defmodule ChatApiWeb.GettingStartedStepsController do
  use ChatApiWeb, :controller

  alias ChatApi.Accounts

  action_fallback(ChatApiWeb.FallbackController)

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with current_user <- Pow.Plug.current_user(conn),
         %{account_id: id} <- current_user do
      _account = Accounts.get_account!(id)
      render(conn, "index.json")
    end
  end
end
