defmodule ChatApi.Repo.Migrations.CreateUpload do
  use Ecto.Migration

  def change do
    create table(:uploads, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:filename, :string)
      add(:file_url, :string)
      add(:content_type, :string)

      timestamps()
    end
  end
end
