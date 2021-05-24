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
            "user_id" => user_id,
            "body" => body
          }
        }
      }) do
    with %{refresh_token: refresh_token} = authorization <-
           Google.get_support_gmail_authorization(account_id, user_id),
         %{gmail_initial_subject: gmail_initial_subject, gmail_thread_id: gmail_thread_id} <-
           Google.get_thread_by_conversation_id(conversation_id),
         %{
           "gmail_message_id" => gmail_message_id,
           "gmail_from" => gmail_from,
           "gmail_to" => gmail_to,
           "gmail_cc" => gmail_cc,
           "gmail_references" => gmail_references
         } = last_gmail_message <- extract_last_gmail_message!(conversation_id) do
      Logger.info("Last Gmail message: #{inspect(last_gmail_message)}")

      # TODO: double check logic for determining from/to/cc/etc
      # TODO: write tests for this logic!
      from =
        refresh_token
        |> Google.Gmail.get_profile()
        |> Map.get("emailAddress")

      sender = Google.format_sender_display_name(authorization, user_id, account_id)
      last_from = Google.Gmail.extract_email_address(gmail_from)
      last_to = gmail_to |> String.split(",") |> Enum.map(&Google.Gmail.extract_email_address/1)

      to =
        if from == last_from do
          last_to
        else
          [last_from | last_to] |> Enum.uniq() |> Enum.reject(&(&1 == from))
        end

      cc =
        case gmail_cc do
          cc when is_binary(cc) ->
            cc |> String.split(",") |> Enum.map(&Google.Gmail.extract_email_address/1)

          _ ->
            []
        end

      references =
        case gmail_references do
          ref when is_binary(ref) -> ref <> " " <> gmail_message_id
          _ -> gmail_message_id
        end

      payload = %{
        from: {sender, from},
        subject: "Re: #{gmail_initial_subject}",
        text: body,
        to: to,
        cc: cc,
        in_reply_to: gmail_message_id,
        references: references,
        thread_id: gmail_thread_id
      }

      Logger.info("Sending payload to Gmail: #{inspect(payload)}")

      %{"id" => gmail_message_id, "threadId" => ^gmail_thread_id} =
        Google.Gmail.send_message(refresh_token, payload)

      Logger.info("Gmail message sent: #{inspect(gmail_message_id)}")

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
