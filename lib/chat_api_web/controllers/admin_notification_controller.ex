defmodule ChatApiWeb.AdminNotificationController do
  use ChatApiWeb, :controller

  action_fallback(ChatApiWeb.FallbackController)

  # TODO: eventually we could potentially use these endpoints for sending feedback/bug reports/etc to admin

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"text" => text} = params) do
    with %{email: email, account_id: account_id} <- conn.assigns.current_user do
      email =
        ChatApi.Emails.send_ad_hoc_email(
          to: System.get_env("PAPERCUPS_ADMIN_EMAIL", "founders@papercups.io"),
          from: email,
          subject: Map.get(params, "subject", "New message from Papercups account #{account_id}"),
          text: text,
          html: Map.get(params, "html")
        )

      # TODO: figure out better error handling?
      case email do
        {:ok, result} -> json(conn, %{data: %{success: true, result: result}})
        {:error, error} -> json(conn, %{data: %{success: false, error: error}})
        error -> json(conn, %{data: %{success: false, error: error}})
      end
    end
  end
end
