defmodule ChatApiWeb.GmailController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, %{"recipient" => recipient, "subject" => subject, "message" => message}) do
    with %{account_id: account_id, email: email} <- conn.assigns.current_user,
         %{refresh_token: refresh_token} <-
           Google.get_authorization_by_account(account_id, %{client: "gmail"}),
         %{token: %{access_token: access_token}} <-
           Google.Auth.get_token!(refresh_token: refresh_token) do
      ChatApi.Emails.send_via_gmail(access_token, %{
        to: recipient,
        from: email,
        subject: subject,
        text: message
      })
      |> case do
        {:ok, result} ->
          json(conn, %{ok: true, data: result})

        error ->
          Logger.error("Error sending email via gmail: #{inspect(error)}")

          json(conn, %{ok: false})
      end
    end
  end
end
