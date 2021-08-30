defmodule ChatApiWeb.SesController do
  use ChatApiWeb, :controller

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(
        conn,
        %{
          "messageId" => ses_message_id,
          "fromAddress" => [from_address],
          "toAddresses" => to_addresses
        } = _payload
      ) do
    IO.inspect(
      %{
        ses_message_id: ses_message_id,
        from_address: from_address,
        to_addresses: to_addresses
      },
      label: "Payload from SES webhook"
    )

    %{
      ses_message_id: ses_message_id,
      from_address: from_address,
      to_addresses: to_addresses
    }
    |> ChatApi.Workers.ProcessSesEvent.new()
    |> Oban.insert()

    send_resp(conn, 200, "")
  end
end
