defmodule ChatApi.Repo.Migrations.AddStripeSubscriptionFields do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:stripe_subscription_id, :string)
      add(:stripe_product_id, :string)

      add(:subscription_plan, :string)
    end
  end
end
