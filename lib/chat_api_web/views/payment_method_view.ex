defmodule ChatApiWeb.PaymentMethodView do
  use ChatApiWeb, :view
  alias ChatApiWeb.PaymentMethodView

  def render("show.json", %{payment_method: payment_method}) do
    %{data: render_one(payment_method, PaymentMethodView, "payment_method.json")}
  end

  def render("payment_method.json", %{payment_method: payment_method}) do
    %{
      id: payment_method.id,
      customer: payment_method.customer,
      brand: payment_method.card.brand,
      country: payment_method.card.country,
      exp_month: payment_method.card.exp_month,
      exp_year: payment_method.card.exp_year,
      last4: payment_method.card.last4
    }
  end
end
