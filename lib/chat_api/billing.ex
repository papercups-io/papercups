defmodule ChatApi.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Messages

  @doc """
  Get billing info from Stripe for the given account
  """
  def get_billing_info(account) do
    %{
      id: account_id,
      stripe_subscription_id: subscription_id,
      stripe_product_id: product_id,
      stripe_default_payment_method_id: payment_method_id,
      subscription_plan: subscription_plan,
      users: users
    } = account

    with {:ok, subscription} <- Stripe.Subscription.retrieve(subscription_id),
         {:ok, product} <- Stripe.Product.retrieve(product_id),
         {:ok, payment_method} <- Stripe.PaymentMethod.retrieve(payment_method_id),
         num_messages <- Messages.count_messages_by_account(account_id) do
      %{
        subscription: subscription,
        product: product,
        payment_method: payment_method,
        subscription_plan: subscription_plan,
        num_messages: num_messages,
        num_users: Enum.count(users)
      }
    else
      # TODO: need to fix this
      _ -> %{}
    end
  end
end
