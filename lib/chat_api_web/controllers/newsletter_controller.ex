defmodule ChatApiWeb.NewsletterController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.{Google, Newsletters}

  @spec subscribe(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def subscribe(conn, %{"newsletter" => newsletter, "email" => email}) do
    # TODO: improve error handling
    try do
      handle_subscription!(newsletter, email)

      json(conn, %{ok: true})
    rescue
      e ->
        json(conn, %{ok: false, error: inspect(e)})
    end
  end

  defp handle_subscription!("pg", email) do
    with {:ok, %{account_id: account_id, sheet_id: sheet_id}} <-
           Newsletters.Pg.get_config(),
         %{refresh_token: token} <-
           Google.get_authorization_by_account(account_id, %{client: "sheets"}) do
      Google.Sheets.append_to_spreadsheet!(token, sheet_id, [email])
    end
  end

  defp handle_subscription!(_subscription_type, _email), do: nil
end
