defmodule ChatApiWeb.AccountController do
  use ChatApiWeb, :controller

  alias ChatApi.Accounts
  alias ChatApi.Accounts.Account

  action_fallback ChatApiWeb.FallbackController

  @spec create(any, map) :: any
  def create(conn, %{"account" => account_params}) do
    with {:ok, %Account{} = account} <- Accounts.create_account(account_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.account_path(conn, :me))
      |> render("create.json", account: account)
    end
  end

  def show(conn, _params) do
    with current_user <- Pow.Plug.current_user(conn),
         %{account_id: id} <- current_user do
      account = Accounts.get_account!(id)
      render(conn, "show.json", account: account)
    end
  end

  def update(conn, %{"account" => account_params}) do
    with current_user <- Pow.Plug.current_user(conn),
         %{account_id: id} <- current_user do
      account = Accounts.get_account!(id)

      with {:ok, %Account{} = account} <- Accounts.update_account(account, account_params) do
        render(conn, "show.json", account: account)
      end
    end
  end

  def delete(conn, _params) do
    with current_user <- Pow.Plug.current_user(conn),
         %{account_id: id} <- current_user do
      account = Accounts.get_account!(id)

      with {:ok, %Account{}} <- Accounts.delete_account(account) do
        send_resp(conn, :no_content, "")
      end
    end
  end

  def me(conn, _params) do
    case conn.assigns.current_user do
      %{account_id: account_id} ->
        account = Accounts.get_account!(account_id)

        render(conn, "show.json", account: account)

      nil ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid token"}})
    end
  end
end
