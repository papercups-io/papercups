defmodule ChatApi.Discord.Client do
  @moduledoc """
  A module to handle interacting with the Discord API
  """

  require Logger

  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://discord.com/api/v8")

  plug(Tesla.Middleware.Headers, [
    {"Content-Type", "application/json; charset=utf-8"},
    {"Authorization", "Bot " <> System.get_env("PAPERCUPS_DISCORD_BOT_TOKEN")}
    # {"User-Agent", "DiscordBot (https://discord.com/api, v8)"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  def retrieve_guild(guild_id, query \\ []) do
    get("/guilds/#{guild_id}", query: query)
  end

  def list_channels(guild_id, query \\ []) do
    get("/guilds/#{guild_id}/channels", query: query)
  end

  def create_channel(guild_id, channel) do
    post("/guilds/#{guild_id}/channels", channel)
  end

  def retrieve_channel(channel_id, query \\ []) do
    get("/channels/#{channel_id}", query: query)
  end

  def delete_channel(channel_id) do
    delete("/channels/#{channel_id}")
  end

  def list_messages(channel_id, query \\ []) do
    get("/channels/#{channel_id}/messages", query: query)
  end

  def send_message(channel_id, message) do
    post("/channels/#{channel_id}/messages", message)
  end

  def get_bot_applications() do
    get("/oauth2/applications/@me")
  end

  def get_current_authorization(access_token) do
    get("/oauth2/@me",
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec get_access_token(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def get_access_token(code) do
    client_id = System.get_env("PAPERCUPS_DISCORD_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_DISCORD_CLIENT_SECRET")

    params = %{
      "code" => code,
      "client_id" => client_id,
      "client_secret" => client_secret,
      "grant_type" => "authorization_code",
      "redirect_uri" => System.get_env("PAPERCUPS_DISCORD_REDIRECT_URI")
    }

    [
      {Tesla.Middleware.BaseUrl, "https://discord.com/api/v8"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers,
       [{"Content-Type", "application/x-www-form-urlencoded;charset=utf-8"}]}
    ]
    |> Tesla.client()
    |> Tesla.post(
      "/oauth2/token",
      params
    )
  end

  @spec refresh_access_token(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def refresh_access_token(refresh_token) do
    client_id = System.get_env("PAPERCUPS_DISCORD_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_DISCORD_CLIENT_SECRET")

    params = %{
      "refresh_token" => refresh_token,
      "client_id" => client_id,
      "client_secret" => client_secret,
      "grant_type" => "refresh_token"
    }

    [
      {Tesla.Middleware.BaseUrl, "https://discord.com/api/v8"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers,
       [{"Content-Type", "application/x-www-form-urlencoded;charset=utf-8"}]}
    ]
    |> Tesla.client()
    |> Tesla.post(
      "/oauth2/token",
      params
    )
  end
end
