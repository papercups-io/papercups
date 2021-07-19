defmodule ChatApi.Mattermost.Client do
  @moduledoc """
  A module for interacting with the Mattermost API.
  """

  require Logger

  alias ChatApi.Mattermost.MattermostAuthorization

  @spec client(MattermostAuthorization.t() | map()) :: Tesla.Client.t()
  def client(%{access_token: token, mattermost_url: url}) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> token}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  @spec send_message(map(), MattermostAuthorization.t()) :: Tesla.Env.result()
  def send_message(%{channel_id: _, message: _} = params, authorization) do
    authorization
    |> client()
    |> Tesla.post("/api/v4/posts", params)
  end

  @spec get_message(binary(), MattermostAuthorization.t()) :: Tesla.Env.result()
  def get_message(post_id, authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/posts/#{post_id}", query: [])
  end

  @spec list_channels(MattermostAuthorization.t() | map()) :: Tesla.Env.result()
  def list_channels(authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/channels", query: [])
  end

  @spec get_channel(binary(), MattermostAuthorization.t()) :: Tesla.Env.result()
  def get_channel(channel_id, authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/channels/#{channel_id}", query: [])
  end

  @spec list_users(MattermostAuthorization.t()) :: Tesla.Env.result()
  def list_users(authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/users", query: [])
  end

  @spec get_user(binary(), MattermostAuthorization.t()) :: Tesla.Env.result()
  def get_user(user_id, authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/users/#{user_id}", query: [])
  end

  @spec list_teams(MattermostAuthorization.t()) :: Tesla.Env.result()
  def list_teams(authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/teams", query: [])
  end

  @spec get_team(binary(), MattermostAuthorization.t()) :: Tesla.Env.result()
  def get_team(team_id, authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/v4/teams/#{team_id}", query: [])
  end
end
