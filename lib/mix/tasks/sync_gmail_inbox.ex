defmodule Mix.Tasks.SyncGmailInbox do
  use Mix.Task

  @shortdoc "Script to test the upcoming Gmail inbox sync feature"

  @moduledoc """
  Example:
  ```
  $ mix sync_gmail_inbox [ACCOUNT_ID] [START_HISTORY_ID]
  ```
  """

  alias ChatApi.Google.Gmail

  def run(args) do
    Application.ensure_all_started(:chat_api)

    with [account_id, start_history_id] <- args,
         %{refresh_token: refresh_token} = authorization <-
           ChatApi.Google.get_authorization_by_account(account_id, %{client: "gmail"}),
         %{"emailAddress" => email} <- Gmail.get_profile(refresh_token) do
      IO.inspect(email, label: "Authenticated email")

      Gmail.list_history(refresh_token,
        start_history_id: start_history_id,
        history_types: "messageAdded",
        label_id: "UNREAD"
      )
      |> Map.get("history", [])
      |> Enum.flat_map(fn h ->
        Enum.map(h["messagesAdded"], fn m -> m["message"] end)
      end)
      |> Enum.uniq_by(fn %{"threadId" => thread_id} -> thread_id end)
      |> Enum.map(fn %{"threadId" => thread_id} ->
        format_thread(thread_id, refresh_token)
      end)
      |> Enum.reject(fn t -> t |> Map.get(:messages, []) |> Enum.empty?() end)
      # For testing
      # |> Enum.slice(0..0)
      |> Enum.each(fn thread ->
        process_thread(thread, authorization)
        # Sleep 1s between each thread
        Process.sleep(1000)
      end)
    else
      error -> IO.inspect("Something went wrong! #{inspect(error)}")
    end
  end

  def process_thread(thread, authorization) do
    IO.inspect(thread, label: "Processing thread")

    with %{account_id: account_id, user_id: user_id} <- authorization,
         %{messages: [_ | _] = messages} <- thread do
      initial_message = List.first(messages)
      was_proactively_sent = initial_message |> Map.get(:label_ids, []) |> Enum.member?("SENT")

      [user_email, customer_email] =
        if was_proactively_sent do
          [initial_message.from, initial_message.to] |> Enum.map(&Gmail.extract_email_address/1)
        else
          [initial_message.to, initial_message.from] |> Enum.map(&Gmail.extract_email_address/1)
        end

      {:ok, customer} = ChatApi.Customers.find_or_create_by_email(customer_email, account_id)

      user =
        case ChatApi.Users.find_user_by_email(user_email, account_id) do
          nil -> ChatApi.Users.find_by_id(user_id, account_id)
          result -> result
        end

      {:ok, conversation} =
        ChatApi.Conversations.create_conversation(%{
          account_id: account_id,
          customer_id: customer.id,
          assignee_id: user.id,
          source: "email"
        })

      conversation
      |> ChatApi.Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> ChatApi.Conversations.Notification.notify(:webhooks, event: "conversation:created")

      Enum.map(messages, fn message ->
        sender_params =
          message
          |> Map.get(:label_ids, [])
          |> Enum.member?("SENT")
          |> case do
            true ->
              user =
                case ChatApi.Users.find_user_by_email(message.from, account_id) do
                  nil -> ChatApi.Users.find_by_id(user_id, account_id)
                  result -> result
                end

              %{user_id: user.id}

            false ->
              {:ok, customer} =
                ChatApi.Customers.find_or_create_by_email(customer_email, account_id)

              %{customer_id: customer.id}
          end

        sender_params
        |> Map.merge(%{
          body: message.formatted_text,
          conversation_id: conversation.id,
          account_id: account_id,
          source: "email",
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
  end

  def format_thread(thread_id, refresh_token) do
    %{
      thread_id: thread_id,
      messages:
        Gmail.get_thread(thread_id, refresh_token)
        |> Gmail.get_thread_messages()
        |> Enum.reject(fn r ->
          Enum.any?(r.label_ids, fn label ->
            Enum.member?(["SPAM", "CATEGORY_PROMOTIONS", "CATEGORY_UPDATES"], label)
          end)
        end)
        |> Enum.map(fn r ->
          r
          |> Map.merge(%{formatted_text: Gmail.remove_original_email(r.text)})
          |> Map.take([
            :to,
            :from,
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
