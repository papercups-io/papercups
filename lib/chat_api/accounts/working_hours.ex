defmodule ChatApi.Accounts.WorkingHours do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:day, :string)
    field(:start_minute, :integer)
    field(:end_minute, :integer)
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:day, :start_minute, :end_minute])
  end
end
