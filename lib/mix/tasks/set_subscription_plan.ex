defmodule Mix.Tasks.SetSubscriptionPlan do
  use Mix.Task

  @shortdoc "Manually updates the subscription plan for the provided account"

  @moduledoc """
  This task handles setting the subscription plan for an account. For example,
  we may automatically upgrade some of our beta users so they can continue to
  use some of our premium features for free.
  """

  def run(args) do
    Application.ensure_all_started(:chat_api)

    case args do
      [account_id, plan] when plan in ["starter", "team"] ->
        account_id
        |> ChatApi.Accounts.get_account!()
        |> ChatApi.Accounts.update_billing_info(%{subscription_plan: plan})

      _ ->
        Mix.shell().info("Invalid args #{inspect(args)}")
        Mix.shell().info("Please specify a valid account ID and subscription plan (starter/team)")
    end
  end
end
