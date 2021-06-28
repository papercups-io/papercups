defmodule Mix.Tasks.SyncGmailInbox do
  use Mix.Task

  @shortdoc "Script to test the upcoming Gmail inbox sync feature"

  @moduledoc """
  Example:
  ```
  $ mix sync_gmail_inbox [ACCOUNT_ID]
  $ mix sync_gmail_inbox [ACCOUNT_ID] [HISTORY_ID]
  $ mix sync_gmail_inbox [ACCOUNT_ID] [HISTORY_ID] [LABEL_ID]
  ```
  """

  require Logger

  alias ChatApi.{Conversations, Customers, Google, Messages, Users}
  alias ChatApi.Google.{Gmail, GmailConversationThread, GoogleAuthorization}

  @spec run([binary()]) :: :ok
  def run(args) do
    Application.ensure_all_started(:chat_api)

    case args do
      [account_id] ->
        sync_messages(account_id)

      [account_id, history_id] ->
        sync_messages(account_id, history_id)

      [account_id, history_id, label_id] ->
        sync_messages_by_label(account_id, history_id, label_id)
    end
  end

  @spec sync_messages(binary()) :: :ok
  def sync_messages(account_id) do
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
      sync(history, authorization)

      {:ok, _auth} =
        Google.update_google_authorization(authorization, %{
          metadata: %{next_history_id: next_history_id}
        })

      :ok
    else
      error -> Logger.info("Unable to sync Gmail messages: #{inspect(error)}")
    end
  end

  @spec sync_messages(binary(), binary()) :: :ok
  def sync_messages(account_id, start_history_id) do
    with %GoogleAuthorization{refresh_token: refresh_token} = authorization <-
           Google.get_authorization_by_account(account_id, %{client: "gmail", type: "support"}),
         %{"emailAddress" => email} <- Gmail.get_profile(refresh_token),
         %{"historyId" => next_history_id, "history" => [_ | _] = history} <-
           Gmail.list_history(refresh_token,
             start_history_id: start_history_id,
             history_types: "messageAdded"
           ) do
      Logger.info("Authenticated email: #{inspect(email)}")
      sync(history, authorization)

      {:ok, _auth} =
        Google.update_google_authorization(authorization, %{
          metadata: %{next_history_id: next_history_id}
        })

      :ok
    else
      error ->
        Logger.info("Unable to sync Gmail messages: #{inspect(error)}")
    end
  end

  @spec sync_messages_by_label(binary(), binary(), binary()) :: :ok | :error
  def sync_messages_by_label(account_id, start_history_id, label_id) do
    with %GoogleAuthorization{refresh_token: refresh_token} = authorization <-
           Google.get_authorization_by_account(account_id, %{client: "gmail", type: "support"}),
         %{"emailAddress" => email} <- Gmail.get_profile(refresh_token),
         %{"historyId" => next_history_id, "history" => [_ | _] = history} <-
           Gmail.list_history(refresh_token,
             start_history_id: start_history_id,
             label_id: label_id
           ) do
      Logger.info("Authenticated email: #{inspect(email)}")
      sync(history, authorization, "labelsAdded")

      {:ok, _auth} =
        Google.update_google_authorization(authorization, %{
          metadata: %{next_history_id: next_history_id}
        })

      :ok
    else
      error ->
        Logger.info("Unable to sync Gmail messages: #{inspect(error)}")
    end
  end

  @spec sync(list(), GoogleAuthorization.t(), binary()) :: :ok
  def sync(
        history,
        %GoogleAuthorization{refresh_token: refresh_token} = authorization,
        event \\ "messagesAdded"
      ) do
    # TODO: handle case where history results exist on next page token
    history
    |> Enum.flat_map(fn h ->
      h |> Map.get(event, []) |> Enum.map(fn m -> m["message"] end)
    end)
    |> Enum.uniq_by(fn %{"threadId" => thread_id} -> thread_id end)
    |> Enum.map(fn %{"threadId" => thread_id} ->
      thread_id
      |> Gmail.get_thread(refresh_token)
      |> Gmail.format_thread(exclude_labels: ["SPAM", "DRAFT", "CATEGORY_PROMOTIONS"])
    end)
    |> Enum.reject(&skip_processing_thread?/1)
    |> Enum.each(fn thread ->
      process_thread(thread, authorization)
      # Sleep 1s between each thread
      Process.sleep(1000)
    end)
  end

  @spec skip_processing_thread?(Gmail.GmailThread.t()) :: boolean
  def skip_processing_thread?(%Gmail.GmailThread{} = thread) do
    case thread do
      %{messages: []} ->
        true

      %{messages: [_ | _] = messages} ->
        Enum.all?(messages, fn msg ->
          Enum.all?(msg.label_ids, fn label ->
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
        %Gmail.GmailMessage{} = message,
        %GoogleAuthorization{
          account_id: account_id,
          user_id: authorization_user_id
        },
        %GmailConversationThread{conversation_id: conversation_id}
      ) do
    sender_email = Gmail.extract_email_address(message.from)
    admin_user = Users.find_user_by_email(sender_email, account_id)
    is_sent = message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

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
    |> Messages.create_and_fetch!()
    |> Messages.Notification.notify(:webhooks)
    |> Messages.Helpers.handle_post_creation_hooks()
  end
end
