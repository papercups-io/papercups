defmodule ChatApi.Workers.SendSesReplyEmail do
  use Oban.Worker, queue: :mailers

  require Logger
  alias ChatApi.{Accounts, Aws, Conversations, Emails, Messages}
  alias ChatApi.Files.FileUpload
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message_id" => message_id}}) do
    with %Message{
           account_id: account_id,
           conversation_id: conversation_id,
           user: %User{} = user
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
      account = Accounts.get_account!(account_id)
      reply_to_address = "reply+#{conversation_id}@chat.papercups.io"
      original_metadata = message.metadata || %{}
      attachments = message.attachments || []

      email = %{
        to: ses_from,
        # TODO: should we use an alias instead of the reply_to_address here?
        from: "#{Emails.format_sender_name(user, account)} <#{reply_to_address}>",
        # reply_to: reply_to_address,
        subject: ses_subject,
        text: message.body,
        in_reply_to: ses_message_id,
        references: references,
        attachments: format_email_attachments(attachments)
      }

      IO.inspect(email, label: "[SendSesReplyEmail] Sending SES email")

      case Aws.send_email(email) do
        %{body: %{message_id: raw_message_id}, status_code: 200} ->
          Messages.update_message(message, %{
            metadata:
              metadata
              |> Map.merge(original_metadata)
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

  def format_email_attachment(%FileUpload{
        file_url: file_url,
        filename: filename,
        content_type: _
      }) do
    case ChatApi.Aws.download_file_url(file_url) do
      {:ok, %{body: data, status_code: 200}} ->
        {filename, data}

      _ ->
        nil
    end
  end

  def format_email_attachment(_), do: nil

  def format_email_attachments(attachments \\ []),
    do: attachments |> Enum.map(&format_email_attachment/1) |> Enum.reject(&is_nil/1)

  def build_references(nil, new_message_id), do: new_message_id

  def build_references(existing_references, new_message_id),
    do: existing_references <> " " <> new_message_id
end
