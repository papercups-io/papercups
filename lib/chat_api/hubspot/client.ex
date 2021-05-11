defmodule ChatApi.Hubspot.Client do
  @moduledoc """
  A module to handle interacting with the HubSpot API
  """

  require Logger

  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.hubapi.com")

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  # TODO: determine whether v1 or v3 API is more reliable/feature-rich

  @spec list_contacts_v1(binary(), keyword()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def list_contacts_v1(access_token, query \\ [count: 100]) do
    get("/contacts/v1/lists/all/contacts/all",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec list_contacts(binary(), keyword()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def list_contacts(access_token, query \\ [limit: 100]) do
    get("/crm/v3/objects/contacts",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec retrieve_contact(binary, any, any) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def retrieve_contact(access_token, contact_id, query \\ []) do
    get("/crm/v3/objects/contacts/#{contact_id}",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec create_contact(binary(), map()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def create_contact(access_token, properties \\ %{}) do
    post(
      "/crm/v3/objects/contacts",
      %{
        "properties" => %{
          "company" => Map.get(properties, "company"),
          "email" => Map.get(properties, "email"),
          "firstname" => Map.get(properties, "first_name"),
          "lastname" => Map.get(properties, "last_name"),
          "phone" => Map.get(properties, "phone"),
          "website" => Map.get(properties, "website")
        }
      },
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec search_contacts(binary(), list()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def search_contacts(access_token, filters \\ []) do
    post("/crm/v3/objects/contacts/search", %{"filters" => filters},
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec find_contact_by_email(binary(), String.t()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def find_contact_by_email(access_token, email) do
    search_contacts(
      access_token,
      [
        %{
          "propertyName" => "email",
          "operator" => "EQ",
          "value" => email
        }
      ]
    )
  end

  @spec refresh_auth_tokens(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def refresh_auth_tokens(refresh_token) do
    create_auth_tokens(%{
      "grant_type" => "refresh_token",
      "refresh_token" => refresh_token
    })
  end

  @spec generate_auth_tokens(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def generate_auth_tokens(code) do
    create_auth_tokens(%{
      "grant_type" => "authorization_code",
      "redirect_uri" => System.get_env("PAPERCUPS_HUBSPOT_REDIRECT_URI"),
      "code" => code
    })
  end

  @spec create_auth_tokens(map()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def create_auth_tokens(params) do
    # app_id = System.get_env("PAPERCUPS_HUBSPOT_APP_ID")
    client_id = System.get_env("PAPERCUPS_HUBSPOT_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_HUBSPOT_CLIENT_SECRET")

    [
      {Tesla.Middleware.BaseUrl, "https://api.hubapi.com"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers,
       [{"Content-Type", "application/x-www-form-urlencoded;charset=utf-8"}]}
    ]
    |> Tesla.client()
    |> Tesla.post(
      "/oauth/v1/token",
      Map.merge(params, %{
        "client_id" => client_id,
        "client_secret" => client_secret
      })
    )
  end
end
