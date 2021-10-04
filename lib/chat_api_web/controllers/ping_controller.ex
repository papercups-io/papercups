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
    params = atomize_keys(data)

    case ChatApi.MessageTemplates.render(html, params) do
      {:ok, result} ->
        json(conn, %{data: result})

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

  # TODO: move into "sql_controller" or "query_controller" or something like that
  @spec sql(Conn.t(), map()) :: Conn.t()
  def sql(conn, %{"credentials" => credentials, "query" => query} = params) do
    data = Map.get(params, "data", [])
    db_opts = parse_postgres_credentials(credentials)

    with {:ok, pid} <- Postgrex.start_link(db_opts),
         {:ok, %Postgrex.Result{columns: columns, rows: rows}} <-
           Postgrex.query(pid, query, data),
         # TODO: not sure if this is the best way to close the connection
         :ok <- GenServer.stop(pid) do
      json(conn, %{
        data: format_sql_results(columns, rows)
      })
    else
      {:error, %DBConnection.ConnectionError{} = e} ->
        conn
        |> put_status(400)
        |> json(%{
          error: %{
            status: 400,
            message: e.message
          }
        })

      {:error, %Postgrex.Error{postgres: details} = e} ->
        conn
        |> put_status(400)
        |> json(%{
          error: %{
            status: 400,
            message: e.message || details.message,
            details: details
          }
        })

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

  @spec parse_postgres_credentials(map()) :: list()
  def parse_postgres_credentials(%{"uri" => uri} = credentials) do
    case parse_postgres_uri(uri) do
      {:ok, results} ->
        results |> parse_postgres_credentials()

      {:error, _} ->
        credentials |> Map.delete("uri") |> parse_postgres_credentials()
    end
  end

  def parse_postgres_credentials(credentials) do
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
  end

  @spec parse_postgres_uri(any) :: {:ok, map()} | {:error, atom()}
  def parse_postgres_uri(uri) when is_binary(uri),
    do: uri |> URI.parse() |> parse_postgres_uri()

  def parse_postgres_uri(%URI{host: nil}), do: {:error, :invalid_host}
  def parse_postgres_uri(%URI{path: nil}), do: {:error, :invalid_database_path}
  def parse_postgres_uri(%URI{userinfo: nil}), do: {:error, :invalid_user_info}

  def parse_postgres_uri(%URI{host: host, path: path, userinfo: user_info})
      when is_binary(host) and is_binary(path) and is_binary(user_info) do
    case String.split(user_info, ":") do
      [username, password] ->
        {:ok,
         %{
           "hostname" => host,
           "database" => String.replace(path, "/", ""),
           "username" => username,
           "password" => password,
           "ssl" => should_use_ssl?(host)
         }}

      _ ->
        {:error, :invalid_user_info}
    end
  end

  def parse_postgres_uri(_), do: {:error, :invalid_uri}

  def should_use_ssl?("localhost"), do: false
  def should_use_ssl?("127.0.0.1"), do: false
  def should_use_ssl?(host) when is_binary(host), do: true
  def should_use_ssl?(_), do: false

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
