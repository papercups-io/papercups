defmodule ChatApi.Workers.SendSesReplyEmail do
  use Oban.Worker, queue: :mailers

  require Logger
  alias ChatApi.{Aws, Conversations, Messages}
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_id" => message_id}}) do
    with %Message{
           conversation_id: conversation_id,
           user: %User{email: sender_email_address}
         } = message <-
           Messages.get_message!(message_id),
         %Message{
           metadata:
             %{
               "ses_message_id" => ses_message_id,
               "ses_references" => ses_references,
               "ses_subject" => ses_subject,
               "ses_from" => ses_from
             } = metadata
         } <- Conversations.get_previous_message(conversation_id, message) do
      references = build_references(ses_references, ses_message_id)

      email = %{
        to: ses_from,
        from: sender_email_address,
        reply_to: "reply+#{conversation_id}@chat.papercups.io",
        subject: ses_subject,
        text: message.body,
        in_reply_to: ses_message_id,
        references: references
      }

      IO.inspect(email, label: "[SendSesReplyEmail] Sending SES email")

      case Aws.send_email(email) do
        %{body: %{message_id: raw_message_id}, status_code: 200} ->
          Messages.update_message(message, %{
            metadata:
              metadata
              |> Map.merge(message.metadata)
              |> Map.merge(%{
                "ses_message_id" => "<#{raw_message_id}@email.amazonses.com>",
                "ses_in_reply_to" => ses_message_id,
                "ses_references" => references,
                "ses_subject" => ses_subject,
                "ses_from" => ses_from
              })
          })
          |> IO.inspect(label: "[SendSesReplyEmail] Successfully replied!")

        error ->
          Logger.error("[SendSesReplyEmail] Failed to send email: #{inspect(error)}")

          nil
      end
    else
      error -> Logger.warn("[SendSesReplyEmail] Something went wrong: #{inspect(error)}")
    end

    :ok
  end

  def build_references(nil, new_message_id), do: new_message_id

  def build_references(existing_references, new_message_id),
    do: existing_references <> " " <> new_message_id
end
