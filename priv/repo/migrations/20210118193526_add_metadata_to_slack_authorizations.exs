defmodule ChatApi.Repo.Migrations.AddMetadataToSlackAuthorizations do
  use Ecto.Migration

  def change do
    alter table(:slack_authorizations) do
      add(:metadata, :map)
    end
  end
end
