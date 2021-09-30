defmodule ChatApiWeb.HubspotController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Hubspot
  alias ChatApi.Hubspot.HubspotAuthorization

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code}) do
    Logger.debug("Code from HubSpot OAuth: #{inspect(code)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         {:ok,
          %{
            status: 200,
            body: %{
              "access_token" => access_token,
              "refresh_token" => refresh_token,
              "expires_in" => expires_in,
              "token_type" => token_type
            }
          }} <-
           Hubspot.Client.generate_auth_tokens(code),
         {:ok,
          %{
            status: 200,
            body: %{
              "app_id" => hubspot_app_id,
              "hub_id" => hubspot_portal_id,
              "scopes" => scopes
            }
          }} <- Hubspot.Client.retrieve_token_info(access_token),
         {:ok, authorization} <-
           Hubspot.create_or_update_authorization(%{
             account_id: account_id,
             user_id: user_id,
             access_token: access_token,
             refresh_token: refresh_token,
             hubspot_app_id: hubspot_app_id,
             hubspot_portal_id: hubspot_portal_id,
             token_type: token_type,
             expires_at: DateTime.utc_now() |> DateTime.add(expires_in),
             scope: Enum.join(scopes, ",")
           }) do
      json(conn, %{data: %{ok: true, id: authorization.id}})
    else
      {:ok, %{status: status, body: body}} ->
        conn
        |> put_status(status)
        |> json(%{
          error: %{
            status: status,
            message: Map.get(body, "message", "Failed to create HubSpot authorization.")
          }
        })

      error ->
        IO.inspect(error, label: "Unexpected error while authorizing Hubspot:")
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    current_user = Pow.Plug.current_user(conn)

    case Hubspot.get_authorization_by_account(current_user.account_id) do
      nil ->
        json(conn, %{data: nil})

      auth ->
        json(conn, %{
          data: %{
            id: auth.id,
            created_at: auth.inserted_at,
            token_type: auth.token_type,
            scope: auth.scope
          }
        })
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %HubspotAuthorization{} = auth <-
           Hubspot.get_hubspot_authorization!(id),
         {:ok, %HubspotAuthorization{}} <- Hubspot.delete_hubspot_authorization(auth) do
      send_resp(conn, :no_content, "")
    end
  end
end
