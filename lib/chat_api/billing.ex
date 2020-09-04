defmodule ChatApi.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Accounts, Messages}

  require Logger

  @trial_period_days 30

  @doc """
  Get billing info from Stripe for the given account
  """
  def get_billing_info(account) do
    %{
      subscription: retrieve_stripe_resource(:subscription, account.stripe_subscription_id),
      product: retrieve_stripe_resource(:product, account.stripe_product_id),
      payment_method:
        retrieve_stripe_resource(:payment_method, account.stripe_default_payment_method_id),
      subscription_plan: account.subscription_plan,
      num_messages: Messages.count_messages_by_account(account.id),
      num_users: Enum.count(account.users)
    }
  end

  # TODO: is this the proper way to handle this?
  # Basically, if the resource id is nil, we just want to return nil;
  # Otherwise, if the id exists, attempt to retrieve it; if it blows up
  # just log the error to Sentry
  def retrieve_stripe_resource(_resource, nil), do: nil

  def retrieve_stripe_resource(:subscription, subscription_id) do
    with {:ok, subscription} <- Stripe.Subscription.retrieve(subscription_id) do
      subscription
    else
      error ->
        Logger.error("Error retrieving subscription: #{inspect(error)}")

        nil
    end
  end

  def retrieve_stripe_resource(:product, product_id) do
    with {:ok, product} <- Stripe.Product.retrieve(product_id) do
      product
    else
      error ->
        Logger.error("Error retrieving product: #{inspect(error)}")

        nil
    end
  end

  def retrieve_stripe_resource(:payment_method, payment_method_id) do
    with {:ok, payment_method} <- Stripe.PaymentMethod.retrieve(payment_method_id) do
      payment_method
    else
      error ->
        Logger.error("Error retrieving payment method: #{inspect(error)}")

        nil
    end
  end

  def find_stripe_product_by_plan(plan) do
    with {:ok, %{data: products}} <- Stripe.Product.list(%{active: true}) do
      Enum.find(products, fn prod -> prod.metadata["name"] == plan end)
    end
  end

  def get_stripe_price_ids_by_product(product) do
    with {:ok, %{data: prices}} <- Stripe.Price.list(%{product: product.id}) do
      Enum.map(prices, fn price -> %{price: price.id} end)
    end
  end

  def get_subscription_items_to_delete(subscription_id) do
    with {:ok, %{items: %{data: items}}} <- Stripe.Subscription.retrieve(subscription_id) do
      Enum.map(items, fn item -> %{id: item.id, deleted: true} end)
    end
  end

  def create_subscription_plan(account, plan) do
    with product <- find_stripe_product_by_plan(plan),
         items <- get_stripe_price_ids_by_product(product),
         {:ok, subscription} <-
           Stripe.Subscription.create(%{
             customer: account.create_subscription_plan,
             items: items,
             trial_period_days: @trial_period_days
           }) do
      Accounts.update_account(account, %{
        stripe_subscription_id: subscription.id,
        stripe_product_id: product.id,
        subscription_plan: plan
      })
    end
  end

  def update_subscription_plan(account, plan) do
    # TODO: put these in a `with`?
    product = find_stripe_product_by_plan(plan)
    new_items = get_stripe_price_ids_by_product(product)
    # TODO: just replace existing item ids with updated price ids?
    # See https://stripe.com/docs/billing/subscriptions/fixed-price#change-price
    items_to_delete = get_subscription_items_to_delete(account.stripe_subscription_id)
    items = new_items ++ items_to_delete

    with {:ok, subscription} <-
           Stripe.Subscription.update(account.stripe_subscription_id, %{items: items}) do
      Accounts.update_account(account, %{
        stripe_subscription_id: subscription.id,
        stripe_product_id: product.id,
        subscription_plan: plan
      })
    end
  end
end
