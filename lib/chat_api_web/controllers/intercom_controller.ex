defmodule ChatApiWeb.IntercomController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Intercom
  alias ChatApi.Intercom.IntercomAuthorization

  action_fallback(ChatApiWeb.FallbackController)

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def callback(conn, %{"code" => code}) do
    Logger.debug("Code from Intercom OAuth: #{inspect(code)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         {:ok,
          %{
            status: 200,
            body: %{
              "access_token" => access_token,
              "token" => token,
              "token_type" => token_type
            }
          }} <-
           Intercom.Client.get_access_token(code),
         {:ok, authorization} <-
           Intercom.create_or_update_authorization(%{
             account_id: account_id,
             user_id: user_id,
             access_token: access_token || token,
             token_type: token_type
           }) do
      json(conn, %{data: %{ok: true, id: authorization.id}})
    else
      {:ok, %{status: status, body: body}} ->
        conn
        |> put_status(status)
        |> json(%{
          error: %{
            status: status,
            message: Map.get(body, "message", "Failed to create Intercom authorization."),
            errors: Map.get(body, "errors", [])
          }
        })

      error ->
        IO.inspect(error, label: "Unexpected error while authorizing Intercom")
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    current_user = Pow.Plug.current_user(conn)

    case Intercom.get_authorization_by_account(current_user.account_id) do
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

  @spec list_contacts(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_contacts(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %IntercomAuthorization{} = authorization <-
           Intercom.get_authorization_by_account(account_id),
         {:ok, %{body: %{"data" => data}}} <- list_intercom_contacts(authorization, params) do
      json(conn, %{
        data: data
      })
    else
      nil -> {:error, :forbidden, "Missing Intercom authorization!"}
      error -> IO.inspect(error, label: "Failed to retrieve Intercom contacts!")
    end
  end

  @spec create_contact(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_contact(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %IntercomAuthorization{} = authorization <-
           Intercom.get_authorization_by_account(account_id),
         {:ok, %{body: contact}} <-
           Intercom.Client.create_contact(authorization, params) do
      json(conn, %{
        data: contact
      })
    else
      nil -> {:error, :forbidden, "Missing Intercom authorization!"}
      error -> IO.inspect(error, label: "Failed to create Intercom contact!")
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %IntercomAuthorization{} = auth <-
           Intercom.get_intercom_authorization!(id),
         {:ok, %IntercomAuthorization{}} <- Intercom.delete_intercom_authorization(auth) do
      send_resp(conn, :no_content, "")
    end
  end

  defp list_intercom_contacts(%IntercomAuthorization{} = authorization, params) do
    case params do
      %{"email" => email} ->
        Intercom.Client.find_contact_by_email(authorization, email)

      %{"query" => query} ->
        Intercom.Client.search_contacts(authorization, query)

      _ ->
        Intercom.Client.list_contacts(authorization)
    end
  end
end
