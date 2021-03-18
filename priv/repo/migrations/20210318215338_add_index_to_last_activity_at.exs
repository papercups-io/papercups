defmodule ChatApi.Repo.Migrations.AddIndexToLastActivityAt do
  use Ecto.Migration

  def change do
    create index(:conversations, [:last_activity_at])
  end
end
