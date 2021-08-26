defmodule ChatApiWeb.SesController do
  use ChatApiWeb, :controller
  require Logger
  alias ChatApi.Aws

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, payload) do
    Logger.debug("Payload from SES webhook: #{inspect(payload)}")
    file_name = payload["messageId"]

    bucket_name = Application.get_env(:chat_api, :ses_bucket_name)
    ses_region = Application.get_env(:chat_api, :ses_region)
    IO.inspect(ses_region)
    {:ok, %{body: body}} = Aws.download_file(bucket_name, file_name, ses_region)

    parsed_email = Mail.Parsers.RFC2822.parse(body)
    Logger.debug("Downloaded email: #{inspect(parsed_email)}")
    send_resp(conn, 200, "")
  end

  # For replies you references and in_reply_to needs to have the message_id
  # the subject has to be the same as the reply thread as well
  def send(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        body: body,
        html_body: html_body,
        from: from,
        in_reply_to: in_reply_to,
        references: references
      ) do
    ExAws.Config

    destination = %{
      to: to,
      cc: cc,
      bcc: bcc
    }

    message =
      Mail.build()
      |> Mail.put_text(body)
      |> Mail.put_to(to)
      |> Mail.put_from(from)
      |> Mail.put_subject(subject)
      |> Mail.Message.put_header("In-Reply-To", in_reply_to)
      |> Mail.Message.put_header("References", references)

    rendered_message = Mail.Renderers.RFC2822.render(message)
    request = ExAws.SES.send_raw_email(rendered_message)

    # SES is only supported in specific region and it is
    # different than our services
    region = Application.get_env(:chat_api, :ses_region)
    res = ExAws.request!(request, %{region: region})
    IO.inspect(res)
  end
end
