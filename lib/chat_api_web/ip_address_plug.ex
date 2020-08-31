defmodule ChatApiWeb.IPAddressPlug do
  @moduledoc """
  A plug to change the `Plug.Conn`'s `remote_ip` to use the values provided by the x-forwarded-for header in the event that the header exists.
  """
  @behaviour Plug

  def init(opts \\ []), do: opts

  def call(conn, _opts) do
    ip = get_ip(conn.req_headers, nil)

    case ip do
      nil -> conn
      _ -> %{conn | remote_ip: ip}
    end
  end

  @spec parse_ip([{String.t(), String.t()}]) :: String.t() | nil
  defp get_ip([], result), do: result |> truncate_header_value |> clean_ip |> parse_ip

  defp get_ip([{"x-forwarded-for", value} | tail], _result),
    do: get_ip(tail, value)

  defp get_ip([_ | tail], result), do: get_ip(tail, result)

  @spec truncate_header_value(String.t()) :: String.t()
  @doc """
    Given this is a "hot path" in the request lifecycle (served on every request) and Cowboy has a default header value size of 4096 bytes,
    we want to avoid the possibility of forkbomb attacks (https://en.wikipedia.org/wiki/Fork_bomb).
    IPv6 addresses are a maximum of 45 characters in length (https://stackoverflow.com/a/7477384)
    Allowing for a reasonable buffer, only process the first 50 bytes of the header value
  """
  def truncate_header_value(<<header_value::bytes-size(50), _rest::binary>> = header)
      when byte_size(header) >= 50,
      do: header_value

  def truncate_header_value(header_value), do: header_value

  @spec clean_ip(String.t()) :: String.t() | nil
  defp clean_ip(ip) when not is_nil(ip) do
    ip |> String.split(",", trim: true) |> List.first()
  end

  defp clean_ip(ip), do: ip

  @spec parse_ip(String.t()) :: :inet.ip_address() | nil
  defp parse_ip(ip) when not is_nil(ip) do
    case :inet.parse_address(to_charlist(ip)) do
      {:ok, ip_address} -> ip_address
      {:error, :einval} -> nil
    end
  end

  defp parse_ip(ip), do: ip
end
