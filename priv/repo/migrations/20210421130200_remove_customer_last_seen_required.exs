defmodule ChatApi.Repo.Migrations.ModifyCusotmerLastSeen do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      modify(:last_seen, :date, null: true)
      modify(:last_seen_at, :utc_datetime, null: false)
    end
  end
end
