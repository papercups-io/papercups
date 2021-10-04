defmodule ChatApi.Intercom.Client do
  @moduledoc """
  A module to handle interacting with the Intercom API
  """

  require Logger

  use Tesla

  alias ChatApi.Intercom.IntercomAuthorization

  plug(Tesla.Middleware.BaseUrl, "https://api.intercom.io")

  plug(Tesla.Middleware.Headers, [
    {"Accept", "application/json"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  def get_access_token(code) do
    client_id = System.get_env("PAPERCUPS_INTERCOM_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_INTERCOM_CLIENT_SECRET")

    [
      {Tesla.Middleware.BaseUrl, "https://api.intercom.io"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers,
       [{"Content-Type", "application/x-www-form-urlencoded;charset=utf-8"}]}
    ]
    |> Tesla.client()
    |> Tesla.post("/auth/eagle/token", %{
      "client_id" => client_id,
      "client_secret" => client_secret,
      "code" => code
    })
  end

  ####################################################################################
  # Conversations
  ####################################################################################

  def list_conversations(authorization, query \\ [])

  def list_conversations(%IntercomAuthorization{access_token: access_token}, query),
    do: list_conversations(access_token, query)

  def list_conversations(access_token, query) when is_binary(access_token) do
    get("/conversations",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  # Example:
  # ```
  #   ChatApi.Intercom.Client.search_conversations(authorization, %{
  #     "field" => "source.author.id",
  #     "operator" => "=",
  #     "value" => contact_id
  #   })
  # ```
  def search_conversations(%IntercomAuthorization{access_token: access_token}, query),
    do: search_conversations(access_token, query)

  def search_conversations(access_token, query) when is_binary(access_token) do
    post("/conversations/search", %{query: query},
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  # NB: Pass in `display_as: "plaintext"` as the query to format messages as text rather than html
  def retrieve_conversation(authorization, conversation_id, query \\ [])

  def retrieve_conversation(
        %IntercomAuthorization{access_token: access_token},
        conversation_id,
        query
      ),
      do: retrieve_conversation(access_token, conversation_id, query)

  def retrieve_conversation(access_token, conversation_id, query) when is_binary(access_token) do
    get("/conversations/#{conversation_id}",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  ####################################################################################
  # Contacts
  ####################################################################################

  def list_contacts(authorization, query \\ [])

  def list_contacts(%IntercomAuthorization{access_token: access_token}, query),
    do: list_contacts(access_token, query)

  def list_contacts(access_token, query) when is_binary(access_token) do
    get("/contacts",
      query: query,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  # Example:
  # ```
  #   ChatApi.Intercom.Client.search_contacts(authorization, %{
  #     "field" => "email",
  #     "operator" => "=",
  #     "value" => "alex@papercups.io"
  #   })
  # ```
  def search_contacts(%IntercomAuthorization{access_token: access_token}, query),
    do: search_contacts(access_token, query)

  def search_contacts(access_token, query) when is_binary(access_token) do
    post("/contacts/search", %{query: query},
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  def find_contact_by_email(%IntercomAuthorization{access_token: access_token}, email),
    do: find_contact_by_email(access_token, email)

  def find_contact_by_email(access_token, email) when is_binary(access_token),
    do: search_contacts(access_token, %{"field" => "email", "operator" => "=", "value" => email})

  def retrieve_contact(%IntercomAuthorization{access_token: access_token}, contact_id),
    do: retrieve_contact(access_token, contact_id)

  def retrieve_contact(access_token, contact_id) when is_binary(access_token) do
    get("/contacts/#{contact_id}",
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  def create_contact(%IntercomAuthorization{access_token: access_token}, params),
    do: create_contact(access_token, params)

  def create_contact(access_token, params) when is_binary(access_token) do
    post("/contacts", params,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end
end
