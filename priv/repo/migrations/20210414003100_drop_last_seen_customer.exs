defmodule ChatApi.Repo.Migrations.DropCusotmerLastSeen do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      remove :last_seen
    end
  end
end
