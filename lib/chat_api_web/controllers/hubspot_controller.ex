defmodule ChatApiWeb.HubspotController do
  use ChatApiWeb, :controller

  require Logger

  action_fallback ChatApiWeb.FallbackController

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code}) do
    IO.inspect("Code from HubSpot OAuth: #{inspect(code)}")

    case ChatApi.Hubspot.Client.generate_auth_tokens(code) do
      {:ok, result} -> json(conn, %{data: %{ok: true, result: result.body}})
      # TODO: not sure how to handle errors here yet
      {:error, reason} -> json(conn, %{data: %{ok: false, result: inspect(reason)}})
    end
  end
end
