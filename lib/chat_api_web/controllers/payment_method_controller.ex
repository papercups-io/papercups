defmodule ChatApiWeb.PaymentMethodController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, StripeClient}

  action_fallback ChatApiWeb.FallbackController

  def create(conn, %{"payment_method" => payment_method_params}) do
    with user <- conn.assigns.current_user,
         %{account_id: account_id} <- user,
         %{"id" => payment_method_id} <- payment_method_params do
      {:ok, payment_method} =
        account_id
        |> StripeClient.find_or_create_customer(user)
        |> StripeClient.add_payment_method(payment_method_id, account_id)

      render(conn, "show.json", payment_method: payment_method)
    end
  end

  @spec show(atom | %{assigns: atom | %{current_user: any}}, any) :: any
  def show(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      case Accounts.get_account!(account_id) do
        %{stripe_default_payment_method_id: nil} ->
          json(conn, %{data: nil})

        %{stripe_default_payment_method_id: payment_method_id} ->
          {:ok, payment_method} = Stripe.PaymentMethod.retrieve(payment_method_id)

          render(conn, "show.json", payment_method: payment_method)
      end
    end
  end
end
