defmodule ChatApi.Workers.SyncGmailInbox do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.{Conversations, Customers, Files, Google, Messages, Users}
  alias ChatApi.Google.{Gmail, GmailConversationThread, GoogleAuthorization}

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    Logger.debug("Syncing Gmail inbox for account: #{inspect(account_id)}")

    sync(account_id)
  end

  @spec sync(binary()) :: :ok
  def sync(account_id) do
    with %GoogleAuthorization{
           refresh_token: refresh_token,
           metadata: %{"next_history_id" => start_history_id}
         } = authorization <-
           Google.get_authorization_by_account(account_id, %{client: "gmail", type: "support"}),
         %{"emailAddress" => email} <- Gmail.get_profile(refresh_token),
         %{"historyId" => next_history_id, "history" => [_ | _] = history} <-
           Gmail.list_history(refresh_token,
             start_history_id: start_history_id,
             history_types: "messageAdded"
           ) do
      Logger.info("Authenticated email: #{inspect(email)}")
      process_history(history, authorization)

      {:ok, _auth} =
        Google.update_google_authorization(authorization, %{
          metadata: %{next_history_id: next_history_id}
        })

      :ok
    else
      %GoogleAuthorization{} ->
        Logger.info(
          "Unable to sync Gmail messages for account #{inspect(account_id)}. " <>
            "Google authorization is either missing :refresh_token or :metadata.next_history_id"
        )

      %{"historyId" => history_id} ->
        Logger.debug(
          "Skipped syncing Gmail messages for account #{inspect(account_id)}. " <>
            "No new message history found since ID #{inspect(history_id)}."
        )

      error ->
        Logger.info(
          "Unable to sync Gmail messages for account #{inspect(account_id)}: #{inspect(error)}"
        )
    end
  end

  @spec process_history(list(), GoogleAuthorization.t(), binary()) :: :ok
  def process_history(
        history,
        %GoogleAuthorization{refresh_token: refresh_token} = authorization,
        event \\ "messagesAdded"
      ) do
    # TODO: handle case where history results exist on next page token
    history
    |> Enum.flat_map(fn h ->
      Enum.map(h[event], fn m -> m["message"] end)
    end)
    |> Enum.uniq_by(fn %{"threadId" => thread_id} -> thread_id end)
    |> Enum.map(fn %{"threadId" => thread_id} ->
      case Gmail.get_thread(thread_id, refresh_token) do
        nil ->
          nil

        thread ->
          Gmail.format_thread(thread, exclude_labels: ["SPAM", "DRAFT", "CATEGORY_PROMOTIONS"])
      end
    end)
    |> Enum.reject(&skip_processing_thread?/1)
    |> Enum.each(fn thread ->
      process_thread(thread, authorization)
      # Sleep 1s between each thread
      Process.sleep(1000)
    end)
  end

  @spec skip_processing_thread?(Gmail.GmailThread.t() | nil) :: boolean
  def skip_processing_thread?(nil), do: true

  def skip_processing_thread?(%Gmail.GmailThread{} = thread) do
    case thread do
      %{messages: []} ->
        true

      %{messages: [_ | _] = messages} ->
        Enum.all?(messages, fn msg ->
          Enum.any?(msg.label_ids, fn label ->
            Enum.member?(["CATEGORY_FORUM", "CATEGORY_UPDATES", "CATEGORY_SOCIAL"], label)
          end)
        end)

      _ ->
        false
    end
  end

  @spec process_thread(Gmail.GmailThread.t(), GoogleAuthorization.t()) :: [Messages.Message.t()]
  def process_thread(
        %Gmail.GmailThread{thread_id: gmail_thread_id} = thread,
        %GoogleAuthorization{} = authorization
      ) do
    Logger.info("Processing thread: #{inspect(thread)}")

    case Google.find_gmail_conversation_thread(%{gmail_thread_id: gmail_thread_id}) do
      nil ->
        handle_new_thread(thread, authorization)

      gmail_conversation_thread ->
        handle_existing_thread(thread, authorization, gmail_conversation_thread)
    end
  end

  @spec handle_existing_thread(
          Gmail.GmailThread.t(),
          GoogleAuthorization.t(),
          GmailConversationThread.t()
        ) :: [Messages.Message.t()]
  def handle_existing_thread(
        %Gmail.GmailThread{messages: [_ | _] = messages} = _thread,
        %GoogleAuthorization{} = authorization,
        %GmailConversationThread{conversation_id: conversation_id} = gmail_conversation_thread
      ) do
    existing_gmail_ids =
      conversation_id
      |> Conversations.get_conversation!()
      |> Map.get(:messages, [])
      |> Enum.map(fn
        %{metadata: %{"gmail_id" => gmail_id}} -> gmail_id
        _ -> nil
      end)
      |> MapSet.new()

    messages
    |> Enum.reject(fn message ->
      MapSet.member?(existing_gmail_ids, message.id)
    end)
    |> Enum.map(fn message ->
      process_new_message(message, authorization, gmail_conversation_thread)
    end)
  end

  @spec handle_new_thread(
          Gmail.GmailThread.t(),
          GoogleAuthorization.t()
        ) :: [Messages.Message.t()]
  def handle_new_thread(
        %Gmail.GmailThread{thread_id: gmail_thread_id, messages: [_ | _] = messages} = _thread,
        %GoogleAuthorization{
          account_id: account_id,
          user_id: authorization_user_id
        } = authorization
      ) do
    initial_message = List.first(messages)
    was_proactively_sent = initial_message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

    [user_email, customer_email] =
      if was_proactively_sent do
        [initial_message.from, initial_message.to] |> Enum.map(&Gmail.extract_email_address/1)
      else
        [initial_message.to, initial_message.from] |> Enum.map(&Gmail.extract_email_address/1)
      end

    # TODO: handle db logic below in a transaction
    {:ok, customer} = Customers.find_or_create_by_email(customer_email, account_id)

    assignee_id =
      case Users.find_user_by_email(user_email, account_id) do
        nil -> authorization_user_id
        result -> result.id
      end

    {:ok, conversation} =
      Conversations.create_conversation(%{
        account_id: account_id,
        customer_id: customer.id,
        assignee_id: assignee_id,
        subject: initial_message.subject,
        source: "email"
      })

    conversation
    |> Conversations.Notification.broadcast_new_conversation_to_admin!()
    |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

    {:ok, gmail_conversation_thread} =
      Google.create_gmail_conversation_thread(%{
        gmail_thread_id: gmail_thread_id,
        gmail_initial_subject: initial_message.subject,
        conversation_id: conversation.id,
        account_id: account_id
      })

    Enum.map(messages, fn message ->
      process_new_message(message, authorization, gmail_conversation_thread)
    end)
  end

  @spec process_new_message(
          Gmail.GmailMessage.t(),
          GoogleAuthorization.t(),
          GmailConversationThread.t()
        ) :: Messages.Message.t()
  def process_new_message(
        %Gmail.GmailMessage{} = gmail_message,
        %GoogleAuthorization{
          account_id: account_id,
          user_id: authorization_user_id
        } = authorization,
        %GmailConversationThread{conversation_id: conversation_id}
      ) do
    sender_email = Gmail.extract_email_address(gmail_message.from)
    admin_user = Users.find_user_by_email(sender_email, account_id)
    is_sent = gmail_message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

    sender_params =
      case {admin_user, is_sent} do
        {%Users.User{id: user_id}, _} ->
          %{user_id: user_id}

        {_, true} ->
          %{user_id: authorization_user_id}

        {_, false} ->
          {:ok, customer} = Customers.find_or_create_by_email(sender_email, account_id)

          %{customer_id: customer.id}
      end

    {:ok, message} =
      sender_params
      |> Map.merge(%{
        body: gmail_message.formatted_text,
        conversation_id: conversation_id,
        account_id: account_id,
        source: "email",
        metadata: Gmail.format_message_metadata(gmail_message),
        sent_at:
          with {unix, _} <- Integer.parse(gmail_message.ts),
               {:ok, datetime} <- DateTime.from_unix(unix, :millisecond) do
            datetime
          else
            _ -> DateTime.utc_now()
          end
      })
      |> Messages.create_message()

    attachment_files_ids =
      gmail_message
      |> Map.get(:attachments, [])
      |> process_message_attachments(authorization)
      |> Enum.map(& &1.id)

    Messages.create_attachments(message, attachment_files_ids)

    message.id
    |> Messages.get_message!()
    |> Messages.Notification.broadcast_to_admin!()
    |> Messages.Notification.notify(:webhooks)
    # NB: we need to make sure the messages are created in the correct order, so we set async: false
    |> Messages.Notification.notify(:slack, async: false)
    |> Messages.Notification.notify(:mattermost, async: false)
    # NB: for email threads, for now we want to reopen the conversation if it was closed
    |> Messages.Helpers.handle_post_creation_hooks()
  end

  def process_message_attachments(nil, _authorization), do: []
  def process_message_attachments([], _authorization), do: []

  def process_message_attachments(
        [_ | _] = attachments,
        %GoogleAuthorization{
          account_id: account_id,
          refresh_token: refresh_token
        } = _authorization
      ) do
    Enum.map(attachments, fn %Gmail.GmailAttachment{filename: filename} = attachment ->
      unique_filename = ChatApi.Aws.generate_unique_filename(filename)
      file_url = Gmail.download_message_attachment(attachment, refresh_token)

      {:ok, file} =
        Files.create_file(%{
          "filename" => filename,
          "unique_filename" => unique_filename,
          "file_url" => file_url,
          "content_type" => attachment.mime_type,
          "account_id" => account_id
        })

      file
    end)
  end
end
