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
      forwarded_to: payload["forwarded_to"],
      received_by: parse_received_by_headers(payload)
    }
    |> ChatApi.Workers.ProcessSesEvent.new()
    |> Oban.insert()

    send_resp(conn, 200, "")
  end

  def webhook(conn, payload) do
    IO.inspect(payload, label: "[Deprecated] Payload from SES webhook")
    IO.inspect("Not doing anything... please use updated webhook handler!")

    send_resp(conn, 200, "")
  end

  @email_regex ~r/(?<user>[a-zA-Z0-9_.-]+)@(?<domain>[a-zA-Z0-9_.-]+\.[a-zA-Z0-9_.-]+)/

  def parse_received_by_headers(headers) when is_list(headers) do
    headers
    |> Enum.filter(fn header ->
      key = header |> Map.get("name", "") |> String.downcase()
      value = header |> Map.get("value", "") |> String.downcase()

      key == "received" && Regex.match?(@email_regex, value)
    end)
    |> Enum.map(fn header ->
      value = header |> Map.get("value", "") |> String.downcase()

      case Regex.scan(@email_regex, value) do
        [[email | _]] -> email
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def parse_received_by_headers(%{"mail" => %{"headers" => headers}}),
    do: parse_received_by_headers(headers)

  def parse_received_by_headers(_), do: []
end
