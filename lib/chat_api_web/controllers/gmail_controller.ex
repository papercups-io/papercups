defmodule ChatApiWeb.GmailController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Google

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(conn, %{"recipient" => recipient, "subject" => subject, "message" => message}) do
    with %{account_id: account_id, email: email, id: user_id} <- conn.assigns.current_user,
         %{refresh_token: refresh_token} <-
           Google.get_support_gmail_authorization(account_id, user_id) do
      Google.Gmail.send_message(refresh_token, %{
        to: recipient,
        from: email,
        subject: subject,
        text: message
      })
      |> case do
        %{"id" => _id} = result ->
          json(conn, %{ok: true, data: result})

        error ->
          Logger.error("Error sending email via gmail: #{inspect(error)}")

          json(conn, %{ok: false})
      end
    end
  end
end
