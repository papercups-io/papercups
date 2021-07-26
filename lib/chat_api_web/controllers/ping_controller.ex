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

  # TODO: move into "template_controller" or something like that
  @spec render(Conn.t(), map()) :: Conn.t()
  def render(conn, %{"html" => html, "data" => data}) do
    try do
      mustache_params = atomize_keys(data)
      eex_params = Map.to_list(mustache_params)
      # TODO: just copy code from https://github.com/schultyy/Mustache.ex instead of using dep?
      result = html |> EEx.eval_string(eex_params) |> Mustache.render(mustache_params)

      json(conn, %{data: result})
    rescue
      e ->
        conn
        |> put_status(400)
        |> json(%{
          error: %{
            status: 400,
            message: e.description
          }
        })
    end
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} ->
      value =
        case v do
          m when is_map(m) -> atomize_keys(m)
          v -> v
        end

      {String.to_atom(k), value}
    end)
  end
end
