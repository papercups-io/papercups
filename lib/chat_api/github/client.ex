defmodule ChatApi.Github.Client do
  @moduledoc """
  A module for interacting with the Github API.
  """

  require Logger

  @spec get_access_token(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def get_access_token(code) do
    client_id = System.get_env("PAPERCUPS_GITHUB_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_GITHUB_CLIENT_SECRET")

    [
      {Tesla.Middleware.BaseUrl, "https://github.com"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers,
       [{"Content-Type", "application/x-www-form-urlencoded;charset=utf-8"}]}
    ]
    |> Tesla.client()
    |> Tesla.post("/login/oauth/access_token", %{
      "client_id" => client_id,
      "client_secret" => client_secret,
      # "redirect_uri" => redirect_uri,
      "code" => code
    })
  end

  @spec client(binary()) :: Tesla.Client.t()
  def client(access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.github.com"},
      {Tesla.Middleware.Headers, [{"Authorization", "token " <> access_token}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end
end
