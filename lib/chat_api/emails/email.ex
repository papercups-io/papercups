defmodule ChatApi.Emails.Email do
  import Swoosh.Email

  @type t :: Swoosh.Email.t()

  def gmail(%{to: to, from: from, subject: subject, text: text} = params) do
    new()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> cc(Map.get(params, :cc, []))
    |> bcc(Map.get(params, :bcc, []))
    |> prepare_gmail_headers(params)
    |> text_body(text)
    |> html_body(Map.get(params, :html))
    |> prepare_gmail_attachments(Map.get(params, :attachments, []))
  end

  def prepare_gmail_headers(message, %{in_reply_to: in_reply_to, references: references}) do
    message
    |> header("In-Reply-To", in_reply_to)
    |> header("References", references)
  end

  def prepare_gmail_headers(message, _), do: message

  # Attachment should look like:
  #
  #   Swoosh.Attachment.new({:data, binary},
  #     content_type: "image/png",
  #     filename: filename,
  #     type: :inline
  #   )
  #
  # Docs: https://hexdocs.pm/swoosh/Swoosh.Attachment.html
  def prepare_gmail_attachments(message, [attachment | rest]) do
    message
    |> attachment(attachment)
    |> prepare_gmail_attachments(rest)
  end

  def prepare_gmail_attachments(message, _), do: message
end
