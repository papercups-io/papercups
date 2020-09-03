defmodule ChatApiWeb.BillingController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, Billing}

  action_fallback ChatApiWeb.FallbackController

  def show(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         billing_info <- Billing.get_billing_info(account) do
      render(conn, "show.json", billing_info: billing_info)
    end
  end

  def create(conn, %{"plan" => plan}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         {:ok, _account} <- Billing.create_subscription_plan(account, plan) do
      json(conn, %{data: %{ok: true}})
    end
  end

  def update(conn, %{"plan" => plan}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         {:ok, _account} <- Billing.update_subscription_plan(account, plan) do
      json(conn, %{data: %{ok: true}})
    end
  end
end
