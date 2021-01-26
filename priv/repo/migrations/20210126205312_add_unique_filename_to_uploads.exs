defmodule ChatApi.Repo.Migrations.AddUniqueFilenameToUploads do
  use Ecto.Migration

  def change do
    alter table(:uploads) do
      add(:unique_filename, :string)
    end

  end
end
