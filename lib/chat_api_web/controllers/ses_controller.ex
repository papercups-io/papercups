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

  # Maybe make this into a map?
  @spec send([binary], [binary], [binary], binary, binary, binary, binary) :: any
  def send(to, cc, bcc, subject, body, html_body, from) do
    ExAws.Config

    destination = %{
      to: to,
      cc: cc,
      bcc: bcc
    }

    message = ExAws.SES.build_message(html_body, body, subject)
    request = ExAws.SES.send_email(destination, message, from, [])

    # SES is only supported in specific region and it is
    # different than our services
    region = Application.get_env(:chat_api, :ses_region)
    res = ExAws.request!(request, %{region: region})
    IO.inspect(res)
  end
end
