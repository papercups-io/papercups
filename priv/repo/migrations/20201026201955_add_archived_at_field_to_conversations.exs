defmodule ChatApi.Repo.Migrations.AddArchivedAtFieldToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add(:archived_at, :utc_datetime)
    end
  end
end
