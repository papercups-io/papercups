defmodule ChatApi.Repo.Migrations.DropCusotmerLastSeen do
  use Ecto.Migration
  import Ecto.Query

  alias ChatApi.Repo

  def change do
    alter table(:customers) do
      remove :last_seen
    end
  end
end
