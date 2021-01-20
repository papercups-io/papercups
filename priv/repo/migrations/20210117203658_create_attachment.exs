defmodule ChatApi.Repo.Migrations.CreateAttachment do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add(:message_id, references(:messages, type: :uuid), null: false)
      add(:upload_id, references(:uploads, type: :uuid), null: false)
      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))

      timestamps()
    end

    create(index(:attachments, [:message_id]))
    create(index(:attachments, [:upload_id]))
    create(index(:attachments, [:account_id]))
    create unique_index(:attachments, [:message_id, :upload_id])
  end
end
