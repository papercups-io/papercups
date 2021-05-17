defmodule ChatApi.Repo.Migrations.RemoveCustomerLastSeenRequirement do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      modify(:last_seen, :date, null: true)
    end
  end
end
