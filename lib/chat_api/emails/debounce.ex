defmodule ChatApi.Emails.Debounce do
  @moduledoc """
  A module to handle email verifications with debounce.io
  """

  require Logger

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.debounce.io/v1"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ]

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  @spec valid?(binary()) :: boolean()
  def valid?(email) do
    case validate(email) do
      {:ok, %{body: %{"debounce" => data}}} ->
        # "Accept-All" || "Deliverable"
        # See: https://debounce.io/resources/help-desk/understanding-results/result-codes/
        data["code"] == "4" || data["code"] == "5"

      {:error, reason} ->
        Logger.error(inspect(reason))

        false

      error ->
        Logger.error("Something went wrong with debounce.io: #{inspect(error)}")

        false
    end
  end

  @spec disposable?(binary()) :: boolean()
  def disposable?(email) do
    [
      {Tesla.Middleware.Headers, [{"content-type", "application/json; charset=utf-8"}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
    ]
    |> Tesla.client()
    |> Tesla.get("https://disposable.debounce.io/", query: [email: email])
    |> case do
      {:ok, %{body: %{"disposable" => "true"}}} ->
        true

      {:ok, %{body: %{"disposable" => "false"}}} ->
        false

      err ->
        Logger.error("Something went wrong checking disposable email: #{inspect(err)}")

        false
    end
  end

  def validate(email) do
    validate(email, has_valid_api_key?())
  end

  def validate(email, true) do
    get("/", query: [email: email, api: System.get_env("PAPERCUPS_DEBOUNCE_API_KEY")])
  end

  def validate(_email, false) do
    {:error, "Invalid debounce.io API key!"}
  end

  @spec enabled?() :: boolean()
  def enabled?(), do: has_valid_api_key?()

  @spec has_valid_api_key?() :: boolean()
  defp has_valid_api_key?() do
    case System.get_env("PAPERCUPS_DEBOUNCE_API_KEY") do
      nil -> false
      "" -> false
      _ -> true
    end
  end
end
