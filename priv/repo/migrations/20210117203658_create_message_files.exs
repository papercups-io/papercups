defmodule ChatApi.Repo.Migrations.CreateMessageFiles do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:filename, :string, null: false)
      add(:file_url, :string, null: false)
      add(:content_type, :string, null: false)
      add(:unique_filename, :string)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
      add(:customer_id, references(:customers, type: :uuid))
      add(:user_id, references(:users, type: :integer))

      timestamps()
    end

    create(index(:files, [:account_id]))
    create(index(:files, [:customer_id]))
    create(index(:files, [:user_id]))

    create table(:message_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add(:message_id, references(:messages, type: :uuid), null: false)
      add(:file_id, references(:files, type: :uuid), null: false)
      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:message_files, [:message_id]))
    create(index(:message_files, [:file_id]))
    create(index(:message_files, [:account_id]))
    create(unique_index(:message_files, [:message_id, :file_id]))
  end
end
