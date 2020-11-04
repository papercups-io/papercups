defmodule ChatApi.Repo.Migrations.CreateUpload do
  use Ecto.Migration

  def change do
    create table(:upload, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:filename, :string)
      add(:file_url, :string)
      add(:content_type, :string)
      add(:message_id, references(:messages, type: :uuid), null: false)

      timestamps()
    end

    create(index(:upload, [:message_id]))
  end
end
