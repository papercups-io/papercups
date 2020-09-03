defmodule ChatApi.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Accounts, Messages}

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

    with subscription <- retrieve_stripe_resource(:subscription, subscription_id),
         product <- retrieve_stripe_resource(:product, product_id),
         payment_method <- retrieve_stripe_resource(:payment_method, payment_method_id),
         num_messages <- Messages.count_messages_by_account(account_id) do
      %{
        subscription: subscription,
        product: product,
        payment_method: payment_method,
        subscription_plan: subscription_plan,
        num_messages: num_messages,
        num_users: Enum.count(users)
      }
    end
  end

  def retrieve_stripe_resource(_resource, nil), do: nil

  def retrieve_stripe_resource(:subscription, subscription_id) do
    with {:ok, subscription} <- Stripe.Subscription.retrieve(subscription_id) do
      subscription
    else
      _error -> nil
    end
  end

  def retrieve_stripe_resource(:product, product_id) do
    with {:ok, product} <- Stripe.Product.retrieve(product_id) do
      product
    else
      _error -> nil
    end
  end

  def retrieve_stripe_resource(:payment_method, payment_method_id) do
    with {:ok, payment_method} <- Stripe.PaymentMethod.retrieve(payment_method_id) do
      payment_method
    else
      _error -> nil
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
    %{stripe_customer_id: customer} = account

    product = find_stripe_product_by_plan(plan)
    items = get_stripe_price_ids_by_product(product)

    with {:ok, subscription} <- Stripe.Subscription.create(%{customer: customer, items: items}) do
      Accounts.update_account(account, %{
        stripe_subscription_id: subscription.id,
        stripe_product_id: product.id,
        subscription_plan: plan
      })
    end
  end

  def update_subscription_plan(account, plan) do
    %{
      stripe_subscription_id: subscription_id
    } = account

    product = find_stripe_product_by_plan(plan)
    new_items = get_stripe_price_ids_by_product(product)
    # TODO: just replace existing item ids with updated price ids?
    # See https://stripe.com/docs/billing/subscriptions/fixed-price#change-price
    items_to_delete = get_subscription_items_to_delete(subscription_id)
    items = new_items ++ items_to_delete

    with {:ok, subscription} <- Stripe.Subscription.update(subscription_id, %{items: items}) do
      Accounts.update_account(account, %{
        stripe_subscription_id: subscription.id,
        stripe_product_id: product.id,
        subscription_plan: plan
      })
    end
  end
end
