defmodule ChatApi.Repo.Migrations.AddStripeFieldsToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:stripe_customer_id, :string)
      add(:stripe_default_payment_method_id, :string)
    end
  end
end
