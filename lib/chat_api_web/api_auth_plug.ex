defmodule ChatApiWeb.APIAuthPlug do
  @moduledoc false
  use Pow.Plug.Base

  alias Plug.Conn
  alias Pow.{Config, Plug, Store.CredentialsCache}
  alias PowPersistentSession.Store.PersistentSessionCache

  @impl true
  @spec fetch(Conn.t(), Config.t()) :: {Conn.t(), map() | nil}
  def fetch(conn, config) do
    conn
    |> fetch_auth_token(config)
    |> fetch_from_store(conn, config)
  end

  defp fetch_from_store(nil, conn, _config), do: {conn, nil}

  defp fetch_from_store(token, conn, config) do
    config
    |> store_config()
    |> CredentialsCache.get(token)
    |> case do
      :not_found -> {conn, nil}
      {user, _metadata} -> {conn, user}
    end
  end

  @impl true
  @spec create(Conn.t(), map(), Config.t()) :: {Conn.t(), map()}
  def create(conn, user, config) do
    store_config = store_config(config)
    token = Pow.UUID.generate()
    renew_token = Pow.UUID.generate()

    conn =
      conn
      |> Conn.put_private(:api_auth_token, sign_token(conn, token, config))
      |> Conn.put_private(:api_renew_token, sign_token(conn, renew_token, config))

    CredentialsCache.put(store_config, token, {user, []})
    PersistentSessionCache.put(store_config, renew_token, {[id: user.id], []})

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

  @doc """
  Create a new token with the provided authorization token.

  The renewal authorization token will be deleted from the store after the user id has been fetched.
  """
  @spec renew(Conn.t(), Config.t()) :: {Conn.t(), map() | nil}
  def renew(conn, config) do
    renew_token = fetch_auth_token(conn, config)
    store_config = store_config(config)
    res = PersistentSessionCache.get(store_config, renew_token)

    PersistentSessionCache.delete(store_config, renew_token)

    case res do
      :not_found -> {conn, nil}
      res -> load_and_create_session(conn, res, config)
    end
  end

  defp load_and_create_session(conn, {clauses, _metadata}, config) do
    case Pow.Operations.get_by(clauses, config) do
      nil -> {conn, nil}
      user -> create(conn, user, config)
    end
  end

  defp sign_token(conn, token, config) do
    Plug.sign_token(conn, signing_salt(), token, config)
  end

  defp signing_salt(), do: Atom.to_string(__MODULE__)

  defp fetch_auth_token(conn, config) do
    # TODO: if token isn't verified, check personal API keys?
    with [token | _rest] <- Conn.get_req_header(conn, "authorization"),
         {:ok, token} <- Plug.verify_token(conn, signing_salt(), token, config) do
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
