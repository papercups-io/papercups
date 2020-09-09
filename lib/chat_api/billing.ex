defmodule ChatApi.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Accounts, Messages}
  alias ChatApi.Accounts.Account

  require Logger

  @trial_period_days 30

  @doc """
  Get billing info from Stripe for the given account
  """
  def get_billing_info(%Account{} = account) do
    with {:ok, subscription} <-
           retrieve_stripe_resource(:subscription, account.stripe_subscription_id),
         {:ok, product} <- retrieve_stripe_resource(:product, account.stripe_product_id),
         {:ok, payment_method} <-
           retrieve_stripe_resource(:payment_method, account.stripe_default_payment_method_id) do
      %{
        subscription: subscription,
        product: product,
        payment_method: payment_method,
        subscription_plan: account.subscription_plan,
        num_messages: Messages.count_messages_by_account(account.id),
        num_users: Enum.count(account.users)
      }
    end
  end

  # TODO: is this the proper way to handle this?
  # Basically, if the resource id is nil, we just want to return nil;
  # Otherwise, if the id exists, attempt to retrieve it
  def retrieve_stripe_resource(_resource, nil), do: {:ok, nil}

  def retrieve_stripe_resource(:subscription, subscription_id),
    do: Stripe.Subscription.retrieve(subscription_id)

  def retrieve_stripe_resource(:product, product_id),
    do: Stripe.Product.retrieve(product_id)

  def retrieve_stripe_resource(:payment_method, payment_method_id),
    do: Stripe.PaymentMethod.retrieve(payment_method_id)

  # TODO: handle errors better?
  def find_stripe_product_by_plan(plan) do
    case Stripe.Product.list(%{active: true}) do
      {:ok, %{data: products}} ->
        products
        |> Enum.find(fn prod -> prod.metadata["name"] == plan end)
        |> case do
          nil -> {:error, :not_found}
          product -> {:ok, product}
        end

      error ->
        error
    end
  end

  # TODO: handle errors better?
  def get_stripe_price_ids_by_product(product) do
    case Stripe.Price.list(%{product: product.id}) do
      {:ok, %{data: prices}} ->
        {:ok, Enum.map(prices, fn price -> %{price: price.id} end)}

      error ->
        error
    end
  end

  # TODO: handle errors better?
  def get_subscription_items_to_delete(subscription_id) do
    case Stripe.Subscription.retrieve(subscription_id) do
      {:ok, %{items: %{data: items}}} ->
        {:ok, Enum.map(items, fn item -> %{id: item.id, deleted: true} end)}

      error ->
        error
    end
  end

  def create_subscription_plan(account, plan) do
    with {:ok, product} <- find_stripe_product_by_plan(plan),
         {:ok, items} <- get_stripe_price_ids_by_product(product),
         {:ok, subscription} <-
           Stripe.Subscription.create(%{
             customer: account.stripe_customer_id,
             items: items,
             trial_period_days: @trial_period_days
           }) do
      Accounts.update_account(account, %{
        stripe_subscription_id: subscription.id,
        stripe_product_id: product.id,
        subscription_plan: plan
      })
    else
      error -> error
    end
  end

  def update_subscription_plan(account, plan) do
    # TODO: just replace existing item ids with updated price ids?
    # See https://stripe.com/docs/billing/subscriptions/fixed-price#change-price
    with {:ok, product} <- find_stripe_product_by_plan(plan),
         {:ok, new_items} <- get_stripe_price_ids_by_product(product),
         {:ok, items_to_delete} <-
           get_subscription_items_to_delete(account.stripe_subscription_id),
         {:ok, subscription} <-
           Stripe.Subscription.update(account.stripe_subscription_id, %{
             items: new_items ++ items_to_delete
           }) do
      Accounts.update_account(account, %{
        stripe_subscription_id: subscription.id,
        stripe_product_id: product.id,
        subscription_plan: plan
      })
    else
      error -> error
    end
  end
end
