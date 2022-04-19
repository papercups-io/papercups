defmodule ChatApi.Repo.Migrations.FixTagNameIndex do
  use Ecto.Migration

  def up do
    drop_if_exists(unique_index(:tags, [:name]))
    create(unique_index(:tags, [:name, :account_id]))
  end

  def down do
    drop(unique_index(:tags, [:name, :account_id]))
  end
end
