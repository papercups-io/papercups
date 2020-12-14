defmodule ChatApiWeb.HubspotController do
  use ChatApiWeb, :controller

  require Logger

  action_fallback ChatApiWeb.FallbackController

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code}) do
    Logger.debug("Code from HubSpot OAuth: #{inspect(code)}")

    case ChatApi.Hubspot.Client.generate_auth_tokens(code) do
      {:ok, result} ->
        json(conn, %{data: %{ok: true, result: result.body}})

      # TODO: figure out a better way to handle errors (e.g. does `reason` include an HTTP status code?)
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{
          error: %{
            status: 400,
            message: inspect(reason)
          }
        })
    end
  end
end
