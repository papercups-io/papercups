defmodule ChatApiWeb.SesController do
  use ChatApiWeb, :controller

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(
        conn,
        %{
          "message_id" => ses_message_id,
          "from_address" => [from_address],
          "to_addresses" => to_addresses
        } = payload
      ) do
    IO.inspect(payload, label: "Payload from SES webhook")

    %{
      ses_message_id: ses_message_id,
      from_address: from_address,
      to_addresses: to_addresses,
      forwarded_to: payload["forwarded_to"]
    }
    |> ChatApi.Workers.ProcessSesEvent.new()
    |> Oban.insert()

    send_resp(conn, 200, "")
  end
end
