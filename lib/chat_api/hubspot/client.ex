defmodule ChatApi.Hubspot.Client do
  @moduledoc """
  A module to handle interacting with the HubSpot API
  """

  require Logger

  use Tesla

  alias ChatApi.Hubspot
  alias ChatApi.Hubspot.HubspotAuthorization

  plug(Tesla.Middleware.BaseUrl, "https://api.hubapi.com")

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  # TODO: determine whether v1 or v3 API is more reliable/feature-rich
  # (May need to use a combination of the two until v3 has everything we need)

  @spec list_contacts_v1(binary() | HubspotAuthorization.t(), keyword()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def list_contacts_v1(authorization, query \\ [count: 100])

  def list_contacts_v1(%HubspotAuthorization{} = authorization, query) do
    authorization |> get_authorization_token() |> list_contacts_v1(query)
  end

  def list_contacts_v1(access_token, query) when is_binary(access_token) do
    get("/contacts/v1/lists/all/contacts/all",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec list_contacts(binary() | HubspotAuthorization.t(), keyword()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def list_contacts(authorization, query \\ [limit: 100])

  def list_contacts(%HubspotAuthorization{} = authorization, query) do
    authorization |> get_authorization_token() |> list_contacts(query)
  end

  def list_contacts(access_token, query) do
    get("/crm/v3/objects/contacts",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec list_companies(binary() | HubspotAuthorization.t(), keyword()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def list_companies(authorization, query \\ [limit: 100])

  def list_companies(%HubspotAuthorization{} = authorization, query) do
    authorization |> get_authorization_token() |> list_companies(query)
  end

  def list_companies(access_token, query) when is_binary(access_token) do
    get("/crm/v3/objects/companies",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec retrieve_contact(binary() | HubspotAuthorization.t(), binary(), any()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def retrieve_contact(authorization, contact_id, query \\ [])

  def retrieve_contact(%HubspotAuthorization{} = authorization, contact_id, query) do
    authorization |> get_authorization_token() |> retrieve_contact(contact_id, query)
  end

  def retrieve_contact(access_token, contact_id, query) when is_binary(access_token) do
    get("/crm/v3/objects/contacts/#{contact_id}",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec create_contact(binary() | HubspotAuthorization.t(), map()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def create_contact(authorization, properties \\ %{})

  def create_contact(%HubspotAuthorization{} = authorization, properties) do
    authorization |> get_authorization_token() |> create_contact(properties)
  end

  def create_contact(access_token, properties) when is_binary(access_token) do
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

  @spec search_contacts(binary() | HubspotAuthorization.t(), list()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def search_contacts(authorization, filters \\ [])

  def search_contacts(%HubspotAuthorization{} = authorization, filters) do
    authorization |> get_authorization_token() |> search_contacts(filters)
  end

  def search_contacts(access_token, filters) when is_binary(access_token) do
    post("/crm/v3/objects/contacts/search", %{"filters" => filters},
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec find_contact_by_email(binary() | HubspotAuthorization.t(), String.t()) ::
          {:error, any()} | {:ok, Tesla.Env.t()}
  def find_contact_by_email(%HubspotAuthorization{} = authorization, email) do
    authorization |> get_authorization_token() |> find_contact_by_email(email)
  end

  def find_contact_by_email(access_token, email) when is_binary(access_token) do
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

  @spec retrieve_account_details(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def retrieve_account_details(access_token) do
    get("/integrations/v1/me",
      query: [access_token: access_token],
      headers: [
        {"Authorization", "Bearer " <> access_token}
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

  @spec retrieve_token_info(binary()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def retrieve_token_info(access_token) do
    get("/oauth/v1/access-tokens/#{access_token}",
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  @spec get_authorization_token(HubspotAuthorization.t()) :: binary() | nil
  def get_authorization_token(%HubspotAuthorization{} = authorization) do
    with true <- Hubspot.is_authorization_expired?(authorization),
         {:ok, refreshed} <- Hubspot.refresh_authorization(authorization) do
      refreshed.access_token
    else
      _ ->
        authorization.access_token
    end
  end
end
