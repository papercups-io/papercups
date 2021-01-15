# TODO: rename to GmailController?
defmodule ChatApiWeb.GmailController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  @doc """
  This action is reached via `/api/gmail/oauth` is the the callback URL that
  Google's OAuth2 provider will redirect the user back to with a `code` that will
  be used to request an access token. The access token will then be used to
  access protected resources on behalf of the user.
  """
  def callback(conn, %{"code" => code}) do
    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         client <- Google.Auth.get_token!(code: code) do
      Logger.debug("Gmail access token: #{inspect(client.token)}")

      case Google.create_or_update_authorization(account_id, %{
             account_id: account_id,
             user_id: user_id,
             access_token: client.token.access_token,
             refresh_token: client.token.refresh_token,
             token_type: client.token.token_type,
             expires_at: client.token.expires_at,
             scope: client.token.other_params["scope"] || "",
             client: "gmail"
           }) do
        {:ok, _result} ->
          json(conn, %{data: %{ok: true}})

        error ->
          Logger.error("Error saving gmail auth: #{inspect(error)}")

          json(conn, %{data: %{ok: false}})
      end
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      case Google.get_authorization_by_account(account_id) do
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

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, %{"recipient" => recipient, "subject" => subject, "message" => message}) do
    with %{account_id: account_id, email: email} <- conn.assigns.current_user,
         %{refresh_token: refresh_token} <-
           Google.get_authorization_by_account(account_id),
         %{token: %{access_token: access_token}} <-
           Google.Auth.get_token!(refresh_token: refresh_token) do
      ChatApi.Emails.send_via_gmail(
        to: recipient,
        from: email,
        subject: subject,
        message: message,
        access_token: access_token
      )
      |> case do
        {:ok, result} ->
          conn
          |> notify_slack()
          |> json(%{ok: true, data: result})

        error ->
          Logger.error("Error sending email via gmail: #{inspect(error)}")

          json(conn, %{ok: false})
      end
    end
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    scope = "https://www.googleapis.com/auth/gmail.modify"

    redirect(conn,
      external:
        Google.Auth.authorize_url!(scope: scope, prompt: "consent", access_type: "offline")
    )
  end

  @spec auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def auth(conn, _params) do
    scope = "https://www.googleapis.com/auth/gmail.modify"
    url = Google.Auth.authorize_url!(scope: scope, prompt: "consent", access_type: "offline")

    json(conn, %{data: %{url: url}})
  end

  @spec notify_slack(Plug.Conn.t()) :: Plug.Conn.t()
  defp notify_slack(conn) do
    with %{email: email} <- conn.assigns.current_user do
      # Putting in an async Task for now, since we don't care if this succeeds
      # or fails (and we also don't want it to block anything)
      Task.start(fn ->
        ChatApi.Slack.Notification.log("#{email} successfully linked Gmail!")
      end)
    end

    conn
  end
end
