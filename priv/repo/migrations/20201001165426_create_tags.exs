defmodule ChatApi.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:description, :string)
      add(:color, :string)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))

      timestamps()
    end

    create(unique_index(:tags, [:name]))
    create(index(:tags, [:account_id]))
    create(index(:tags, [:creator_id]))

    create table(:conversation_tags, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all))
      add(:tag_id, references(:tags, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))

      timestamps()
    end

    create(unique_index(:conversation_tags, [:account_id, :conversation_id, :tag_id]))
    create(index(:conversation_tags, [:account_id]))
    create(index(:conversation_tags, [:creator_id]))
    create(index(:conversation_tags, [:conversation_id]))
    create(index(:conversation_tags, [:tag_id]))

    create table(:customer_tags, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:customer_id, references(:customers, type: :uuid, on_delete: :delete_all))
      add(:tag_id, references(:tags, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))

      timestamps()
    end

    create(unique_index(:customer_tags, [:account_id, :customer_id, :tag_id]))
    create(index(:customer_tags, [:account_id]))
    create(index(:customer_tags, [:creator_id]))
    create(index(:customer_tags, [:customer_id]))
    create(index(:customer_tags, [:tag_id]))
  end
end
