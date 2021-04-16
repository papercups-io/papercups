defmodule ChatApi.Repo.Migrations.DropCusotmerLastSeen do
  use Ecto.Migration
  import Ecto.Query

  alias ChatApi.Repo

  def change do
    from(
      c in "customers",
      where: is_nil(c.last_seen_at),
      update: [set: [last_seen_at: c.last_seen]]
    )
    |> Repo.update_all([])

    alter table(:customers) do
      remove :last_seen
    end
  end
end
