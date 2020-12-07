defmodule ChatApi.StripeClient do
  @moduledoc """
  The StripeClient context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Accounts, Repo}
  alias ChatApi.Accounts.Account

  @spec enabled? :: boolean()
  def enabled?() do
    case System.get_env("PAPERCUPS_STRIPE_SECRET") do
      "sk_" <> _rest -> true
      _ -> false
    end
  end

  @spec add_payment_method(
          binary(),
          binary(),
          binary()
        ) ::
          {:ok, Stripe.PaymentMethod.t()} | {:error, Stripe.Error.t()}
  @doc """
  Add a payment method to an account via Stripe
  """
  def add_payment_method(customer_id, payment_method_id, account_id) do
    payment_method =
      Stripe.PaymentMethod.attach(%{payment_method: payment_method_id, customer: customer_id})

    Stripe.Customer.update(customer_id, %{
      invoice_settings: %{default_payment_method: payment_method_id}
    })

    Account
    |> Repo.get!(account_id)
    |> Accounts.update_billing_info(%{stripe_default_payment_method_id: payment_method_id})

    payment_method
  end

  @spec find_or_create_customer(binary(), map()) :: binary() | nil
  @doc """
  Find or create the Stripe customer token for the given account
  """
  def find_or_create_customer(account_id, user) do
    case Repo.get!(Account, account_id) do
      %{company_name: name, stripe_customer_id: nil} = account ->
        {:ok, customer} = Stripe.Customer.create(%{name: name, email: user.email})
        stripe_customer_id = customer.id
        Accounts.update_billing_info(account, %{stripe_customer_id: stripe_customer_id})

        stripe_customer_id

      %{stripe_customer_id: customer_id} ->
        customer_id

      _account ->
        nil
    end
  end
end
