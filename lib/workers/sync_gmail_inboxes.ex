defmodule ChatApi.Workers.SyncGmailInboxes do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Google.{Gmail, GoogleAuthorization}

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Logger.info("Syncing Gmail inboxes: #{inspect(job)}")

    %{client: "gmail"}
    |> ChatApi.Google.list_google_authorizations()
    |> Enum.each(&sync_gmail_authorization/1)

    :ok
  end

  def sync_gmail_authorization(%GoogleAuthorization{} = authorization) do
    # Note that the "next_history_id" needs to be set on the GoogleAuthorization metadata
    with %{refresh_token: refresh_token, metadata: %{"next_history_id" => start_history_id}} <-
           authorization,
         %{"emailAddress" => email} <- Gmail.get_profile(refresh_token),
         %{"historyId" => next_history_id, "history" => [_ | _] = history} <-
           Gmail.list_history(refresh_token,
             start_history_id: start_history_id,
             history_types: "messageAdded"
           ) do
      IO.inspect(email, label: "Authenticated email")

      # TODO: handle case where history results exist on next page token
      history
      |> Enum.flat_map(fn h ->
        Enum.map(h["messagesAdded"], fn m -> m["message"] end)
      end)
      |> Enum.uniq_by(fn %{"threadId" => thread_id} -> thread_id end)
      |> Enum.map(fn %{"threadId" => thread_id} ->
        format_thread(thread_id, refresh_token)
      end)
      |> Enum.reject(fn t -> t |> Map.get(:messages, []) |> Enum.empty?() end)
      |> Enum.each(fn thread ->
        process_thread(thread, authorization)
        # Sleep 1s between each thread
        Process.sleep(1000)
      end)

      {:ok, _auth} =
        ChatApi.Google.update_google_authorization(authorization, %{
          metadata: %{next_history_id: next_history_id}
        })
    else
      error -> IO.inspect("Unable to sync Gmail messages: #{inspect(error)}")
    end
  end

  def process_thread(%{thread_id: gmail_thread_id} = thread, authorization) do
    IO.inspect(thread, label: "Processing thread")

    case ChatApi.Google.find_gmail_conversation_thread(%{gmail_thread_id: gmail_thread_id}) do
      nil ->
        handle_new_thread(thread, authorization)

      gmail_conversation_thread ->
        handle_existing_thread(thread, authorization, gmail_conversation_thread)
    end
  end

  # TODO: DRY these up below a bit

  def handle_existing_thread(
        %{messages: [_ | _] = messages} = _thread,
        %{
          account_id: account_id,
          user_id: authorization_user_id
        } = _authorization,
        %{conversation_id: conversation_id} = _gmail_conversation_thread
      ) do
    existing_message_ids =
      conversation_id
      |> ChatApi.Conversations.get_conversation!()
      |> Map.get(:messages, [])
      |> Enum.map(fn
        %{metadata: %{"gmail_id" => gmail_id}} -> gmail_id
        _ -> nil
      end)
      |> MapSet.new()

    messages
    |> Enum.reject(fn message ->
      MapSet.member?(existing_message_ids, message.id)
    end)
    |> Enum.map(fn message ->
      sender_email = Gmail.extract_email_address(message.from)
      admin_user = ChatApi.Users.find_user_by_email(sender_email, account_id)
      is_sent = message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

      sender_params =
        case {admin_user, is_sent} do
          {%ChatApi.Users.User{id: user_id}, _} ->
            %{user_id: user_id}

          {_, true} ->
            %{user_id: authorization_user_id}

          {_, false} ->
            {:ok, customer} = ChatApi.Customers.find_or_create_by_email(sender_email, account_id)

            %{customer_id: customer.id}
        end

      sender_params
      |> Map.merge(%{
        body: message.formatted_text,
        conversation_id: conversation_id,
        account_id: account_id,
        source: "email",
        metadata: Gmail.format_message_metadata(message),
        sent_at:
          with {unix, _} <- Integer.parse(message.ts),
               {:ok, datetime} <- DateTime.from_unix(unix, :millisecond) do
            datetime
          else
            _ -> DateTime.utc_now()
          end
      })
      |> ChatApi.Messages.create_and_fetch!()
      |> ChatApi.Messages.Notification.broadcast_to_admin!()
      |> ChatApi.Messages.Notification.notify(:webhooks)
      # NB: we need to make sure the messages are created in the correct order, so we set async: false
      |> ChatApi.Messages.Notification.notify(:slack, async: false)
      # |> ChatApi.Messages.Notification.notify(:mattermost, async: false)
      # TODO: not sure we need to do this on every message
      |> ChatApi.Messages.Helpers.handle_post_creation_conversation_updates()
    end)
  end

  def handle_new_thread(
        %{thread_id: gmail_thread_id, messages: [_ | _] = messages} = _thread,
        %{
          account_id: account_id,
          user_id: authorization_user_id
        } = _authorization
      ) do
    initial_message = List.first(messages)
    was_proactively_sent = initial_message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

    [user_email, customer_email] =
      if was_proactively_sent do
        [initial_message.from, initial_message.to] |> Enum.map(&Gmail.extract_email_address/1)
      else
        [initial_message.to, initial_message.from] |> Enum.map(&Gmail.extract_email_address/1)
      end

    {:ok, customer} = ChatApi.Customers.find_or_create_by_email(customer_email, account_id)

    assignee_id =
      case ChatApi.Users.find_user_by_email(user_email, account_id) do
        nil -> authorization_user_id
        result -> result.id
      end

    {:ok, conversation} =
      ChatApi.Conversations.create_conversation(%{
        account_id: account_id,
        customer_id: customer.id,
        assignee_id: assignee_id,
        source: "email"
      })

    conversation
    |> ChatApi.Conversations.Notification.broadcast_new_conversation_to_admin!()
    |> ChatApi.Conversations.Notification.notify(:webhooks, event: "conversation:created")

    {:ok, _gmail_conversation_thread} =
      ChatApi.Google.create_gmail_conversation_thread(%{
        gmail_thread_id: gmail_thread_id,
        gmail_initial_subject: initial_message.subject,
        conversation_id: conversation.id,
        account_id: account_id
      })

    Enum.map(messages, fn message ->
      sender_email = Gmail.extract_email_address(message.from)
      admin_user = ChatApi.Users.find_user_by_email(sender_email, account_id)
      is_sent = message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

      sender_params =
        case {admin_user, is_sent} do
          {%ChatApi.Users.User{id: user_id}, _} ->
            %{user_id: user_id}

          {_, true} ->
            %{user_id: authorization_user_id}

          {_, false} ->
            {:ok, customer} = ChatApi.Customers.find_or_create_by_email(sender_email, account_id)

            %{customer_id: customer.id}
        end

      sender_params
      |> Map.merge(%{
        body: message.formatted_text,
        conversation_id: conversation.id,
        account_id: account_id,
        source: "email",
        metadata: Gmail.format_message_metadata(message),
        sent_at:
          with {unix, _} <- Integer.parse(message.ts),
               {:ok, datetime} <- DateTime.from_unix(unix, :millisecond) do
            datetime
          else
            _ -> DateTime.utc_now()
          end
      })
      |> ChatApi.Messages.create_and_fetch!()
      |> ChatApi.Messages.Notification.broadcast_to_admin!()
      |> ChatApi.Messages.Notification.notify(:webhooks)
      # NB: we need to make sure the messages are created in the correct order, so we set async: false
      |> ChatApi.Messages.Notification.notify(:slack, async: false)
      # |> ChatApi.Messages.Notification.notify(:mattermost, async: false)
      # TODO: not sure we need to do this on every message
      |> ChatApi.Messages.Helpers.handle_post_creation_conversation_updates()
    end)
  end

  def format_thread(thread_id, refresh_token) do
    # TODO: use struct
    %{
      thread_id: thread_id,
      messages:
        Gmail.get_thread(thread_id, refresh_token)
        |> Gmail.get_thread_messages()
        |> Enum.reject(fn r ->
          Enum.any?(r.label_ids, fn label ->
            Enum.member?(["SPAM", "DRAFT", "CATEGORY_PROMOTIONS"], label)
          end)
        end)
        |> Enum.map(fn r ->
          r
          |> Map.merge(%{formatted_text: Gmail.remove_original_email(r.text)})
          |> Map.take([
            :to,
            :from,
            :cc,
            :bcc,
            :subject,
            :formatted_text,
            :label_ids,
            :in_reply_to,
            :references,
            :snippet,
            :ts,
            :thread_id,
            :id,
            :message_id,
            :history_id
          ])
        end)
    }
  end
end
