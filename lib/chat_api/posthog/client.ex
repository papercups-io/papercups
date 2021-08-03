defmodule ChatApi.Posthog.Client do
  @moduledoc """
  The PostHog API client.
  """

  @posthog_cloud_url "https://app.posthog.com"

  @spec client(binary(), binary()) :: Tesla.Client.t()
  def client(url, token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer " <> token}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  @spec client(binary() | map()) :: Tesla.Client.t()
  def client(%{posthog_url: url, personal_api_key: token} = authorization)
      when is_map(authorization),
      do: client(url, token)

  def client(token) when is_binary(token),
    do: client(@posthog_cloud_url, token)

  @spec events(binary() | map()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def events(_, query \\ [])

  def events(authorization, query) when is_map(authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/event", query: query)
  end

  def events(token, query) when is_binary(token) do
    token
    |> client()
    |> Tesla.get("/api/event", query: query)
  end

  @spec persons(binary() | map()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def persons(_, query \\ [])

  def persons(authorization, query) when is_map(authorization) do
    authorization
    |> client()
    |> Tesla.get("/api/person", query: query)
  end

  def persons(token, query) when is_binary(token) do
    token
    |> client()
    |> Tesla.get("/api/person", query: query)
  end
end
