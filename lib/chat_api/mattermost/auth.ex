defmodule ChatApi.Mattermost.Auth do
  use OAuth2.Strategy

  # TODO: allow dynamic Mattermost URL (e.g. pull from `mattermost_authorizations` table)

  def client do
    OAuth2.Client.new(
      strategy: __MODULE__,
      client_id: System.get_env("PAPERCUPS_MATTERMOST_CLIENT_ID"),
      client_secret: System.get_env("PAPERCUPS_MATTERMOST_CLIENT_SECRET"),
      redirect_uri: System.get_env("PAPERCUPS_MATTERMOST_REDIRECT_URI"),
      site: System.get_env("PAPERCUPS_MATTERMOST_URL"),
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/access_token"
    )
  end

  def refresh_client() do
    OAuth2.Client.new(
      strategy: OAuth2.Strategy.Refresh,
      client_id: System.get_env("PAPERCUPS_MATTERMOST_CLIENT_ID"),
      client_secret: System.get_env("PAPERCUPS_MATTERMOST_CLIENT_SECRET"),
      site: System.get_env("PAPERCUPS_MATTERMOST_URL"),
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/access_token"
    )
  end

  def authorize_url!(params \\ []) do
    OAuth2.Client.authorize_url!(client(), params)
  end

  # You can pass options to the underlying http library via `opts` parameter
  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    case params do
      [refresh_token: refresh_token] when not is_nil(refresh_token) ->
        OAuth2.Client.get_token!(refresh_client(), params, headers, opts)

      _ ->
        OAuth2.Client.get_token!(client(), params, headers, opts)
    end
  end

  # Strategy Callbacks
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
