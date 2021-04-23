defmodule ChatApi.Github.Client do
  @moduledoc """
  A module for interacting with the Github API.
  """

  require Logger

  alias ChatApi.Github.GithubAuthorization

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
      "code" => code
    })
  end

  @spec oauth_client(binary()) :: Tesla.Client.t()
  def oauth_client(access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.github.com"},
      {Tesla.Middleware.Headers, [{"Authorization", "token " <> access_token}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  @spec app_client(binary()) :: Tesla.Client.t()
  def app_client(jwt) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.github.com"},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> jwt}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  def generate_installation_access_token(installation_id) do
    jwt()
    |> app_client()
    |> Tesla.post("/app/installations/#{installation_id}/access_tokens", %{})
  end

  def retrieve_app() do
    jwt()
    |> app_client()
    |> Tesla.get("/app")
  end

  def retrieve_installation(%GithubAuthorization{github_installation_id: installation_id}),
    do: retrieve_installation(installation_id)

  def retrieve_installation(installation_id) do
    jwt()
    |> app_client()
    |> Tesla.get("/app/installations/#{installation_id}")
  end

  def delete_installation(%GithubAuthorization{github_installation_id: installation_id}),
    do: delete_installation(installation_id)

  def delete_installation(installation_id) do
    jwt()
    |> app_client()
    |> Tesla.delete("/app/installations/#{installation_id}")
  end

  def list_installation_repos(%GithubAuthorization{github_installation_id: installation_id}),
    do: list_installation_repos(installation_id)

  def list_installation_repos(installation_id) do
    {:ok, %{body: %{"token" => token}}} = generate_installation_access_token(installation_id)

    token
    |> oauth_client()
    |> Tesla.get("/installation/repositories")
  end

  def list_issues(%GithubAuthorization{github_installation_id: installation_id}, owner, repo),
    do: list_issues(installation_id, owner, repo)

  def list_issues(installation_id, owner, repo) do
    {:ok, %{body: %{"token" => token}}} = generate_installation_access_token(installation_id)

    token
    |> oauth_client()
    |> Tesla.get("/repos/#{owner}/#{repo}/issues")
  end

  defp jwt() do
    ChatApi.Github.Token.generate_and_sign!(%{}, Joken.Signer.parse_config(:rs256))
  end
end
