defmodule ChatApiWeb.PublicAPIAuthPlug do
  @moduledoc false
  use Pow.Plug.Base

  alias Plug.Conn
  alias Pow.{Config, Store.CredentialsCache}

  @impl true
  @spec fetch(Conn.t(), Config.t()) :: {Conn.t(), map() | nil}
  def fetch(conn, config) do
    conn
    |> fetch_auth_token(config)
    |> fetch_user(conn, config)
  end

  defp fetch_user(nil, conn, _config), do: {conn, nil}

  defp fetch_user(token, conn, config) do
    case fetch_from_store(token, config) do
      nil -> fetch_and_cache_user(token, conn, config)
      user -> {conn, user}
    end
  end

  defp fetch_and_cache_user(token, conn, config) do
    case ChatApi.Users.find_by_api_key(token) do
      nil ->
        {conn, nil}

      user ->
        config
        |> store_config()
        |> CredentialsCache.put(token, {user, []})

        {conn, user}
    end
  end

  defp fetch_from_store(token, config) do
    config
    |> store_config()
    |> CredentialsCache.get(token)
    |> case do
      :not_found -> nil
      {user, _metadata} -> user
    end
  end

  @impl true
  @spec create(Conn.t(), map(), Config.t()) :: {Conn.t(), map()}
  def create(conn, user, _config) do
    {conn, user}
  end

  @impl true
  @spec delete(Conn.t(), Config.t()) :: Conn.t()
  def delete(conn, config) do
    case fetch_auth_token(conn, config) do
      nil ->
        :ok

      token ->
        config
        |> store_config()
        |> CredentialsCache.delete(token)
    end

    conn
  end

  defp fetch_auth_token(conn, _config) do
    with [token | _rest] <- Conn.get_req_header(conn, "authorization"),
         "Bearer " <> token <- token do
      token
    else
      _any -> nil
    end
  end

  defp store_config(config) do
    backend = Config.get(config, :cache_store_backend, Pow.Store.Backend.EtsCache)

    [backend: backend]
  end
end
