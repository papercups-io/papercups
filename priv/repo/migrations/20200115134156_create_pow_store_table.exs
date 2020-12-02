defmodule Pow.Postgres.Repo.Migrations.CreateTablePowStore do
  use Ecto.Migration

  def change do
    create table("pow_store", primary_key: false) do
      add :namespace, :text
      add :key, {:array, :bytea}
      add :original_key, :bytea
      add :value, :bytea
      add :expires_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index("pow_store", [:namespace, :original_key])
  end
end
