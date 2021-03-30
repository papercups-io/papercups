defmodule ChatApi.Workers.SendGmailNotification do
  @moduledoc false

  use Oban.Worker, queue: :mailers
  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.{Conversations, Google, Messages}

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{
        args: %{
          "message" => %{
            "id" => message_id,
            "account_id" => account_id,
            "conversation_id" => conversation_id,
            "body" => body
          }
        }
      }) do
    with %{refresh_token: refresh_token} = _authorization <-
           Google.get_authorization_by_account(account_id, %{client: "gmail"}),
         %{gmail_initial_subject: gmail_initial_subject, gmail_thread_id: gmail_thread_id} <-
           Google.get_thread_by_conversation_id(conversation_id),
         %{
           "gmail_message_id" => gmail_message_id,
           "gmail_from" => gmail_from,
           "gmail_to" => gmail_to,
           "gmail_cc" => gmail_cc,
           "gmail_references" => gmail_references
         } = last_gmail_message <- extract_last_gmail_message!(conversation_id) do
      Logger.debug("Last Gmail message: #{inspect(last_gmail_message)}")

      # TODO: double check logic for determining from/to/cc/etc
      from =
        refresh_token
        |> Google.Gmail.get_profile()
        |> Map.get("emailAddress")

      last_from = Google.Gmail.extract_email_address(gmail_from)
      last_to = Google.Gmail.extract_email_address(gmail_to)

      to =
        if from == last_from do
          last_to
        else
          last_from
        end

      payload = %{
        from: from,
        subject: "Re: " <> gmail_initial_subject,
        text: body,
        to: to,
        cc: Google.Gmail.extract_email_address(gmail_cc),
        in_reply_to: gmail_message_id,
        references: gmail_references <> " " <> gmail_message_id,
        thread_id: gmail_thread_id
      }

      %{"id" => gmail_message_id, "threadId" => ^gmail_thread_id} =
        Google.Gmail.send_message(refresh_token, payload)

      Logger.debug("Gmail message sent: #{inspect(gmail_message_id)}")

      metadata =
        gmail_message_id
        |> Google.Gmail.get_message(refresh_token)
        |> Google.Gmail.format_thread_message()
        |> Google.Gmail.format_message_metadata()

      message_id
      |> Messages.get_message!()
      |> Messages.update_message(%{metadata: metadata})
    else
      error -> Logger.info("Skipped sending Gmail notification: #{inspect(error)}")
    end

    :ok
  end

  def extract_last_gmail_message!(conversation_id) do
    conversation_id
    |> Conversations.get_conversation!()
    |> Map.get(:messages, [])
    |> Enum.map(& &1.metadata)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1["gmail_ts"])
    |> List.last()
  end
end
