defmodule ChatApi.Repo.Migrations.CreatePowSessions do
  use Ecto.Migration

  def change do
    create table("pow_sessions", primary_key: false) do
      add(:namespace, :text)
      add(:key, {:array, :bytea})
      add(:original_key, :bytea)
      add(:value, :bytea)
      add(:expires_at, :utc_datetime)
      timestamps(type: :utc_datetime)
    end

    create(unique_index("pow_sessions", [:namespace, :original_key]))
  end
end
