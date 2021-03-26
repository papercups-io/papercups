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
         %{refresh_token: refresh_token} = _authorization <-
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
      |> Enum.map(fn %{"threadId" => thread_id} ->
        # TODO:
        # get user from google authorization?
        # find or create customer by email
        # create new conversation with customer
        # then, loop through each message
        # if sender is agent, use user from google auth
        # otherwise, find or create customer by email

        format_thread(thread_id, refresh_token)

        # %{
        #   "body" => formatted_message,
        #   "conversation_id" => conversation_id,
        #   "account_id" => account_id,
        #   "sent_at" => ts,
        #   "source" => "gmail",
        #   "type" => "email" ???
        #   "user_id"/"customer_id" => etc
        # }
      end)
      |> IO.inspect()
    end
  end

  def format_thread(thread_id, refresh_token) do
    %{
      thread_id: thread_id,
      messages:
        Gmail.get_thread(thread_id, refresh_token)
        |> Gmail.get_thread_messages()
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
            :message_id
          ])
        end)
    }
  end
end
