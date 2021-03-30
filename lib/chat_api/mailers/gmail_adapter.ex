defmodule ChatApi.Mailers.GmailAdapter do
  @moduledoc """
  A parser that handles formatting email payloads to send via the Gmail API

  For reference [Gmail API docs](https://developers.google.com/gmail/api)

  You don't need to set `from` address as google will set it for you.
  If you still want to include it, make sure it matches the account or
  it will be ignored.

  ## Dependency

  Gmail adapter requires `Mail` dependency to format message as RFC 2822 message.

  Because `Mail` library removes Bcc headers, they are being added after email is
  rendered.

  ## Required config parameters
    - `:access_token` valid OAuth2 access token
        Required scopes:
        - gmail.compose
      See https://developers.google.com/oauthplayground when developing
  """

  alias Swoosh.Email

  def parse(%Email{} = email, config) do
    %{
      raw: email |> prepare_body() |> Base.encode64(),
      threadId: config[:thread_id]
    }
  end

  defp prepare_body(email) do
    Mail.build_multipart()
    |> prepare_from(email)
    |> prepare_to(email)
    |> prepare_cc(email)
    |> prepare_bcc(email)
    |> prepare_subject(email)
    |> prepare_text(email)
    |> prepare_html(email)
    |> prepare_attachments(email)
    |> prepare_reply_to(email)
    |> prepare_custom_headers(email)
    |> Mail.Renderers.RFC2822.render()
    # When message is rendered, bcc header will be removed and we need to prepend bcc list to the
    # begining of the message. Gmail will handle it from there.
    # https://github.com/DockYard/elixir-mail/blob/v0.2.0/lib/mail/renderers/rfc_2822.ex#L139
    |> prepend_bcc(email)
  end

  defp prepare_from(body, %{from: nil}), do: body
  defp prepare_from(body, %{from: from}), do: Mail.put_from(body, from)

  defp prepare_to(body, %{to: []}), do: body
  defp prepare_to(body, %{to: to}), do: Mail.put_to(body, to)

  defp prepare_cc(body, %{cc: []}), do: body
  defp prepare_cc(body, %{cc: cc}), do: Mail.put_cc(body, cc)

  defp prepare_bcc(rendered_mail, %{bcc: []}), do: rendered_mail
  defp prepare_bcc(rendered_mail, %{bcc: bcc}), do: Mail.put_bcc(rendered_mail, bcc)

  defp prepend_bcc(rendered_message, %{bcc: []}), do: rendered_message

  defp prepend_bcc(rendered_message, %{bcc: bcc}),
    do: Mail.Renderers.RFC2822.render_header("bcc", bcc) <> "\r\n" <> rendered_message

  defp prepare_subject(body, %{subject: subject}), do: Mail.put_subject(body, subject)

  defp prepare_text(body, %{text_body: nil}), do: body
  defp prepare_text(body, %{text_body: text_body}), do: Mail.put_text(body, text_body)

  defp prepare_html(body, %{html_body: nil}), do: body
  defp prepare_html(body, %{html_body: html_body}), do: Mail.put_html(body, html_body)

  defp prepare_attachments(body, %{attachments: attachments}) do
    Enum.reduce(attachments, body, &prepare_attachment/2)
  end

  defp prepare_attachment(attachment, body) do
    Mail.put_attachment(body, {attachment.filename, Swoosh.Attachment.get_content(attachment)})
  end

  defp prepare_reply_to(body, %{reply_to: nil}), do: body
  defp prepare_reply_to(body, %{reply_to: reply_to}), do: Mail.put_reply_to(body, reply_to)

  defp prepare_custom_headers(body, %{headers: headers}) do
    Enum.reduce(headers, body, fn {key, value}, acc ->
      Mail.Message.put_header(acc, key, value)
    end)
  end
end
