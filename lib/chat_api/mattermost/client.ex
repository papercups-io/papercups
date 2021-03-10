defmodule ChatApi.Mattermost.Client do
  @moduledoc """
  A module for interacting with the Mattermost API.
  """

  require Logger

  use Tesla

  # TODO: allow dynamic Mattermost URL (e.g. pull from `mattermost_authorizations` table)

  plug(
    Tesla.Middleware.BaseUrl,
    System.get_env("PAPERCUPS_MATTERMOST_URL")
  )

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  @spec send_message(map(), binary()) :: Tesla.Env.result() | {:ok, nil}
  def send_message(%{channel_id: _, message: _} = params, access_token) do
    post("/api/v4/posts", params,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec get_message(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def get_message(post_id, access_token) do
    get("/api/v4/posts/#{post_id}",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec list_channels(binary()) :: {:ok, nil} | Tesla.Env.result()
  def list_channels(access_token) do
    get("/api/v4/channels",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec get_channel(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def get_channel(channel_id, access_token) do
    get("/api/v4/channels/#{channel_id}",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec list_users(binary()) :: {:ok, nil} | Tesla.Env.result()
  def list_users(access_token) do
    get("/api/v4/users",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec get_user(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def get_user(user_id, access_token) do
    get("/api/v4/users/#{user_id}",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec list_teams(binary()) :: {:ok, nil} | Tesla.Env.result()
  def list_teams(access_token) do
    get("/api/v4/teams",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec get_team(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def get_team(team_id, access_token) do
    get("/api/v4/teams/#{team_id}",
      query: [],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end
end
