defmodule ChatApiWeb.PaymentMethodController do
  use ChatApiWeb, :controller

  alias ChatApi.Stripe

  action_fallback ChatApiWeb.FallbackController

  def create(conn, %{"payment_method" => payment_method_params}) do
    with user <- conn.assigns.current_user,
         %{account_id: account_id} <- user,
         %{"id" => payment_method_id} <- payment_method_params do
      {:ok, _data} =
        account_id
        |> Stripe.find_or_create_customer(user)
        |> Stripe.add_payment_method(payment_method_id)

      json(conn, %{data: %{ok: true}})
    end
  end
end
