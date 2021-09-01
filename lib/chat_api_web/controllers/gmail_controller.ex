defmodule ChatApiWeb.GmailController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google
  alias ChatApi.Google.GoogleAuthorization

  @spec profile(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def profile(conn, _params) do
    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         %GoogleAuthorization{refresh_token: refresh_token} <-
           Google.get_support_gmail_authorization(account_id, user_id) do
      case Google.Gmail.get_profile(refresh_token) do
        %{"emailAddress" => email} ->
          json(conn, %{ok: true, data: %{email: email}})

        error ->
          Logger.error("Error retrieving gmail profile: #{inspect(error)}")

          json(conn, %{ok: false, data: nil})
      end
    else
      _ -> {:error, :forbidden, "Authorization required"}
    end
  end

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, params) do
    with %{account_id: account_id, email: email, id: user_id} <- conn.assigns.current_user,
         %{refresh_token: refresh_token} <-
           Google.get_support_gmail_authorization(account_id, user_id) do
      Google.Gmail.send_message(refresh_token, %{
        to: params["to"] || params["recipient"],
        from: params["from"] || email,
        subject: params["subject"],
        text: params["text"] || params["message"]
      })
      |> case do
        %{"id" => _id} = result ->
          json(conn, %{ok: true, data: result})

        error ->
          Logger.error("Error sending email via gmail: #{inspect(error)}")

          json(conn, %{ok: false})
      end
    else
      _ -> {:error, :forbidden, "Authorization required"}
    end
  end
end
