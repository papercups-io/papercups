defmodule ChatApiWeb.PingController do
  use ChatApiWeb, :controller

  alias Plug.Conn

  require Logger

  @spec ping(Conn.t(), map()) :: Conn.t()
  def ping(conn, params) do
    Logger.info("Params from /api/ping:")
    Logger.info(inspect(params))

    json(conn, %{
      data: %{
        message: "Pong!",
        params: params
      }
    })
  end
end
