defmodule ChatApi.Repo.Migrations.AddAccountsAssociations do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:conversations) do
      add(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:users) do
      add(:account_id, references(:accounts, type: :uuid), null: false)
    end

    create(index(:messages, [:account_id]))
    create(index(:conversations, [:account_id]))
    create(index(:users, [:account_id]))
  end
end
