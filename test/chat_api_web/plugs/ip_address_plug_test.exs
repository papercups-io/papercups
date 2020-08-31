defmodule ChatApiWeb.IPAddressPlugTest do
  @moduledoc """
  Tests for the ChatApiWeb.IPAddressPlug plug
  """
  use ExUnit.Case, async: true
  use Plug.Test
  alias ChatApiWeb.IPAddressPlug

  @x_forwarded_for_header "x-forwarded-for"
  @ipv4_default {127, 0, 0, 1}
  @ipv6_default {0, 0, 0, 0, 0, 0, 0, 1}
  defp make_call(conn, header, value) do
    c = if header, do: put_req_header(conn, header, value), else: conn
    IPAddressPlug.call(c, []).remote_ip
  end

  defp test_ipv4_conn(header \\ nil, value \\ nil) do
    c = %{conn("GET", "/") | remote_ip: @ipv4_default}
    make_call(c, header, value)
  end

  defp test_ipv6_conn(header \\ nil, value \\ nil) do
    c = %{conn("GET", "/") | remote_ip: @ipv6_default}
    make_call(c, header, value)
  end

  defp random_number_string(n) do
    charset = '012345678'

    Enum.reduce(0..(n - 1), [], fn _i, acc ->
      [Enum.random(charset) | acc]
    end)
    |> to_string()
  end

  describe "IPAddressPlug.truncate_header_value " do
    test "truncates the first 50 chars/bytes of the header's value" do
      first_50 = random_number_string(50)
      next_250 = random_number_string(250)

      combined = "#{first_50}#{next_250}"

      assert IPAddressPlug.truncate_header_value(combined) == first_50
    end

    test "doesn't truncate a header value less than 50 chars/bytes in length" do
      first_45 = random_number_string(45)

      assert IPAddressPlug.truncate_header_value(first_45) == first_45
    end
  end

  describe "IPAddressPlug.call " do
    test "does not touch conn.remote_ip if there's no x-forwarded-for header present" do
      assert test_ipv4_conn() == @ipv4_default
      assert test_ipv6_conn() == @ipv6_default
    end

    test "does not touch conn.remote_ip if a x-forwarded-for header exists but contains an invalid value" do
      assert test_ipv4_conn(@x_forwarded_for_header, "invalid header") ==
               @ipv4_default

      assert test_ipv4_conn(@x_forwarded_for_header, "invalid 1, invalid 2, invalid 3") ==
               @ipv4_default
    end

    test "returns valid remote_ip when the x-forwarded-for header is present" do
      assert test_ipv4_conn(@x_forwarded_for_header, "203.0.113.1,198.51.100.101,198.51.100.102") ==
               {203, 0, 113, 1}

      assert test_ipv4_conn(
               @x_forwarded_for_header,
               "203.0.113.1, 198.51.100.101, 198.51.100.102"
             ) ==
               {203, 0, 113, 1}

      assert test_ipv4_conn(@x_forwarded_for_header, "203.0.113.1") ==
               {203, 0, 113, 1}

      assert test_ipv6_conn(
               @x_forwarded_for_header,
               "0004:a63f:dbd5:ca43:46b4:3da2:4e5d:03d2,3347:b17f:a4c9:019e:67ec:bb88:31f3:f5c5,1596:6fe0:866e:a17e:3134:3f5c:fa80:e1bb,3aa0:b189:8a73:1f3c:a1cf:2d95:2753:719b"
             ) ==
               {4, 42_559, 56_277, 51_779, 18_100, 15_778, 20_061, 978}

      assert test_ipv6_conn(
               @x_forwarded_for_header,
               "0004:a63f:dbd5:ca43:46b4:3da2:4e5d:03d2, 3347:b17f:a4c9:019e:67ec:bb88:31f3:f5c5, 1596:6fe0:866e:a17e:3134:3f5c:fa80:e1bb, 3aa0:b189:8a73:1f3c:a1cf:2d95:2753:719b"
             ) ==
               {4, 42_559, 56_277, 51_779, 18_100, 15_778, 20_061, 978}

      assert test_ipv6_conn(
               @x_forwarded_for_header,
               "0004:a63f:dbd5:ca43:46b4:3da2:4e5d:03d2"
             ) ==
               {4, 42_559, 56_277, 51_779, 18_100, 15_778, 20_061, 978}
    end
  end
end
