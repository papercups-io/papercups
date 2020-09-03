defmodule ChatApiWeb.BillingView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{BillingView, PaymentMethodView}

  def render("show.json", %{billing_info: billing_info}) do
    %{data: render_one(billing_info, BillingView, "billing_info.json", as: :billing_info)}
  end

  def render("billing_info.json", %{billing_info: billing_info}) do
    %{
      payment_method:
        render_one(billing_info.payment_method, PaymentMethodView, "payment_method.json"),
      subscription:
        render_one(billing_info.subscription, BillingView, "subscription.json", as: :subscription),
      product: render_one(billing_info.product, BillingView, "product.json", as: :product),
      subscription_plan: billing_info.subscription_plan,
      num_users: billing_info.num_users,
      num_messages: billing_info.num_messages
    }
  end

  def render("subscription.json", %{subscription: subscription}) do
    %{
      id: subscription.id,
      livemode: subscription.livemode,
      start_date: subscription.start_date,
      status: subscription.status,
      current_period_start: subscription.current_period_start,
      trial_start: subscription.trial_start,
      trial_end: subscription.trial_end,
      days_until_due: subscription.days_until_due,
      quantity: subscription.quantity,
      prices:
        subscription.items.data
        |> Enum.map(fn item -> item.price end)
        |> render_many(BillingView, "price.json", as: :price)
    }
  end

  def render("price.json", %{price: price}) do
    %{
      id: price.id,
      active: price.active,
      unit_amount: price.unit_amount,
      currency: price.currency,
      amount_decimal: price.amount_decimal,
      created: price.created,
      billing_scheme: price.billing_scheme,
      interval: price.recurring.interval,
      interval_count: price.recurring.interval_count,
      product_id: price.product
    }
  end

  def render("product.json", %{product: product}) do
    %{
      id: product.id,
      name: product.name,
      active: product.active,
      code: product.metadata["name"] || nil
    }
  end
end
