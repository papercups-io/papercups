defmodule ChatApi.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:first_seen, :date, null: false)
      add(:last_seen, :date, null: false)
      add(:account_id, references(:accounts, type: :uuid))

      timestamps()
    end

    alter table(:messages) do
      add(:customer_id, references(:customers, type: :uuid))
    end

    alter table(:conversations) do
      add(:customer_id, references(:customers, type: :uuid))
    end

    create(index(:messages, [:customer_id]))
    create(index(:conversations, [:customer_id]))
    create(index(:customers, [:account_id]))
  end
end
