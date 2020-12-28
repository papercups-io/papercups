defmodule ChatApi.Repo.Migrations.AddClosedAtToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add(:closed_at, :utc_datetime)
    end
  end
end
