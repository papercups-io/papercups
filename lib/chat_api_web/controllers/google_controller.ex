defmodule ChatApiWeb.GoogleController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  @doc """
  This action is reached via `/api/google/oauth` is the the callback URL that
  Google's OAuth2 provider will redirect the user back to with a `code` that will
  be used to request an access token. The access token will then be used to
  access protected resources on behalf of the user.
  """
  def callback(conn, %{"code" => code} = params) do
    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         client <- Google.Auth.get_token!(code: code) do
      Logger.debug("Gmail access token: #{inspect(client.token)}")
      scope = client.token.other_params["scope"] || params["scope"] || ""

      type =
        cond do
          String.contains?(scope, "spreadsheets") -> "sheets"
          String.contains?(scope, "gmail") -> "gmail"
          true -> raise "Unrecognized scope: #{scope}"
        end

      case Google.create_or_update_authorization(account_id, %{
             account_id: account_id,
             user_id: user_id,
             access_token: client.token.access_token,
             refresh_token: client.token.refresh_token,
             token_type: client.token.token_type,
             expires_at: client.token.expires_at,
             scope: scope,
             client: type
           }) do
        {:ok, _result} ->
          enqueue_enabling_gmail_sync(account_id)

          json(conn, %{data: %{ok: true}})

        error ->
          Logger.error("Error saving sheets auth: #{inspect(error)}")

          json(conn, %{data: %{ok: false}})
      end
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, %{"client" => client}) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      case Google.get_authorization_by_account(account_id, %{client: client}) do
        nil ->
          json(conn, %{data: nil})

        auth ->
          json(conn, %{
            data: %{
              created_at: auth.inserted_at,
              account_id: auth.account_id,
              user_id: auth.user_id,
              scope: auth.scope
            }
          })
      end
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, %{"client" => client}) do
    scope =
      case client do
        "sheets" -> "https://www.googleapis.com/auth/spreadsheets"
        "gmail" -> "https://www.googleapis.com/auth/gmail.modify"
        _ -> raise "Unrecognized client: #{client}"
      end

    redirect(conn,
      external:
        Google.Auth.authorize_url!(scope: scope, prompt: "consent", access_type: "offline")
    )
  end

  @spec auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth(conn, %{"client" => client}) do
    scope =
      case client do
        "sheets" -> "https://www.googleapis.com/auth/spreadsheets"
        "gmail" -> "https://www.googleapis.com/auth/gmail.modify"
        _ -> raise "Unrecognized client: #{client}"
      end

    url = Google.Auth.authorize_url!(scope: scope, prompt: "consent", access_type: "offline")

    json(conn, %{data: %{url: url}})
  end

  defp enqueue_enabling_gmail_sync(account_id) do
    %{account_id: account_id}
    |> ChatApi.Workers.EnableGmailInboxSync.new()
    |> Oban.insert()
  end
end
