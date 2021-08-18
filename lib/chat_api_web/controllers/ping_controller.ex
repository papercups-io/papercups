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

  # TODO: move into "sql_controller" or "query_controller" or something like that
  @spec sql(Conn.t(), map()) :: Conn.t()
  def sql(conn, %{"credentials" => credentials, "query" => query} = params) do
    data = Map.get(params, "data", [])

    db_opts =
      Enum.filter(
        %{
          hostname: Map.get(credentials, "hostname", "localhost"),
          database: Map.get(credentials, "database", "chat_api_dev"),
          username: Map.get(credentials, "username"),
          password: Map.get(credentials, "password"),
          ssl: Map.get(credentials, "ssl")
        },
        fn
          {_k, nil} -> false
          {_k, ""} -> false
          _ -> true
        end
      )

    with {:ok, pid} <- Postgrex.start_link(db_opts),
         {:ok, %Postgrex.Result{columns: columns, rows: rows}} <- Postgrex.query(pid, query, data) do
      json(conn, %{
        data: format_sql_results(columns, rows)
      })
    else
      {:error, e} ->
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

  defp format_sql_results(columns, rows) do
    rows
    |> Enum.map(fn r ->
      Enum.map(r, fn item ->
        if String.valid?(item) do
          item
        else
          case Ecto.UUID.cast(item) do
            {:ok, uuid} -> uuid
            _ -> item
          end
        end
      end)
    end)
    |> Enum.map(fn r ->
      columns |> Enum.zip(r) |> Map.new()
    end)
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
