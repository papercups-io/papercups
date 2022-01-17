defmodule ChatApiWeb.BillingController do
  require Logger
  use ChatApiWeb, :controller
  alias ChatApi.{Accounts, Billing}

  action_fallback(ChatApiWeb.FallbackController)

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         billing_info <- Billing.get_billing_info(account) do
      render(conn, "show.json", billing_info: billing_info)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"plan" => plan}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         plan <- format_plan_by_edition(plan),
         {:ok, _account} <- Billing.create_subscription_plan(account, plan) do
      conn
      |> notify_slack(plan)
      |> json(%{data: %{ok: true}})
    end
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"plan" => plan}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         plan <- format_plan_by_edition(plan),
         {:ok, _account} <- Billing.update_subscription_plan(account, plan) do
      conn
      |> notify_slack(plan)
      |> json(%{data: %{ok: true}})
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         account <- Accounts.get_account!(account_id),
         {:ok, _account} <- Billing.cancel_subscription_plan(account) do
      conn
      |> notify_slack(nil)
      |> json(%{data: %{ok: true}})
    end
  end

  @spec notify_slack(Plug.Conn.t(), binary() | nil) :: Plug.Conn.t()
  defp notify_slack(conn, plan) do
    with %{email: email} <- conn.assigns.current_user do
      # Putting in an async Task for now, since we don't care if this succeeds
      # or fails (and we also don't want it to block anything)
      Task.start(fn ->
        case plan do
          nil -> ChatApi.Slack.Notification.log("#{email} canceled their subscription")
          _ -> ChatApi.Slack.Notification.log("#{email} set subscription plan to #{plan}")
        end
      end)
    end

    conn
  end

  @spec format_plan_by_edition(binary()) :: binary()
  defp format_plan_by_edition(plan) do
    if is_eu_edition?() do
      "eu-" <> plan
    else
      plan
    end
  end

  @spec is_eu_edition?() :: boolean()
  defp is_eu_edition?() do
    case System.get_env("REACT_APP_EU_EDITION") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
