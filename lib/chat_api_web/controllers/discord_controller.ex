defmodule ChatApiWeb.DiscordController do
  use ChatApiWeb, :controller

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code} = payload) do
    Logger.debug("Code from Discord OAuth: #{inspect(code)}")

    with {:ok, %{body: response}} <- ChatApi.Discord.Client.get_access_token(code) do
      json(conn, %{
        data: %{ok: true, data: response}
      })
    else
      {:error, error} ->
        json(conn, %{
          data: %{ok: false, error: error, data: payload}
        })
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    json(conn, %{data: nil})
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => _}) do
    send_resp(conn, :no_content, "")
  end
end
