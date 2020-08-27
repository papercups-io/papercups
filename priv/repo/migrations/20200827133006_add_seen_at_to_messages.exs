defmodule ChatApi.Repo.Migrations.AddSeenAtToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:seen_at, :utc_datetime)
    end
  end
end
