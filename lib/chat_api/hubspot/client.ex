defmodule ChatApi.Hubspot.Client do
  @moduledoc """
  A module to handle interacting with the HubSpot API
  """

  require Logger

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.hubapi.com"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ]

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  def list_contacts_v1(access_token) do
    get("/contacts/v1/lists/all/contacts/all",
      query: [count: 5],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  def list_contacts_v3(access_token) do
    get("/crm/v3/objects/contacts",
      query: [limit: 5],
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  def generate_auth_tokens(code) do
    # app_id = System.get_env("PAPERCUPS_HUBSPOT_APP_ID")
    grant_type = "authorization_code"
    client_id = System.get_env("PAPERCUPS_HUBSPOT_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_HUBSPOT_CLIENT_SECRET")
    redirect_uri = System.get_env("PAPERCUPS_HUBSPOT_REDIRECT_URI")

    [
      {Tesla.Middleware.BaseUrl, "https://api.hubapi.com"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers,
       [{"Content-Type", "application/x-www-form-urlencoded;charset=utf-8"}]}
    ]
    |> Tesla.client()
    |> Tesla.post("/oauth/v1/token", %{
      "grant_type" => grant_type,
      "client_id" => client_id,
      "client_secret" => client_secret,
      "redirect_uri" => redirect_uri,
      "code" => code
    })
  end
end
