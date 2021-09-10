defmodule ChatApi.Google.Auth do
  use OAuth2.Strategy

  @spec client(keyword()) :: OAuth2.Client.t()
  def client(params \\ []) do
    OAuth2.Client.new(
      strategy: __MODULE__,
      client_id: System.get_env("PAPERCUPS_GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("PAPERCUPS_GOOGLE_CLIENT_SECRET"),
      redirect_uri:
        Keyword.get(params, :redirect_uri, System.get_env("PAPERCUPS_GOOGLE_REDIRECT_URI")),
      site: "https://accounts.google.com",
      authorize_url: "/o/oauth2/auth",
      token_url: "/o/oauth2/token"
    )
  end

  @spec refresh_client() :: OAuth2.Client.t()
  def refresh_client() do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.Refresh,
      client_id: System.get_env("PAPERCUPS_GOOGLE_CLIENT_ID"),
      client_secret: System.get_env("PAPERCUPS_GOOGLE_CLIENT_SECRET"),
      site: "https://accounts.google.com",
      authorize_url: "/o/oauth2/auth",
      token_url: "/o/oauth2/token"
    )
  end

  @spec authorize_url!(keyword()) :: binary()
  def authorize_url!(params \\ []) do
    params
    |> client()
    |> OAuth2.Client.authorize_url!(params)
  end

  # You can pass options to the underlying http library via `opts` parameter
  @spec get_access_token!(keyword(), [{binary(), binary()}], keyword()) :: OAuth2.Client.t()
  def get_access_token!(params \\ [], headers \\ [], opts \\ []) do
    case params do
      [refresh_token: refresh_token] when not is_nil(refresh_token) ->
        OAuth2.Client.get_token!(refresh_client(), params, headers, opts)

      _ ->
        params |> client() |> OAuth2.Client.get_token!(params, headers, opts)
    end
  end

  @spec get_access_token(keyword(), [{binary(), binary()}], keyword()) ::
          {:error, any()} | {:ok, OAuth2.Client.t()}
  def get_access_token(params \\ [], headers \\ [], opts \\ []) do
    case params do
      [refresh_token: refresh_token] when not is_nil(refresh_token) ->
        OAuth2.Client.get_token(refresh_client(), params, headers, opts)

      _ ->
        params |> client() |> OAuth2.Client.get_token(params, headers, opts)
    end
  end

  # Strategy Callbacks

  @spec authorize_url(OAuth2.Client.t(), keyword()) :: OAuth2.Client.t()
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params \\ [], headers \\ []) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
