defmodule Pow.Postgres.Schema do
  use Ecto.Schema

  @primary_key false
  schema "pow_store" do
    field :namespace, :string
    field :key, {:array, :binary}
    field :original_key, :binary
    field :value, :binary
    field :expires_at, :utc_datetime
    timestamps(type: :utc_datetime)
  end
end
