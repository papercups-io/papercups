defmodule ChatApi.Accounts.WorkingHours do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.WorkingHours

  @day_to_indexes %{
    "everyday" => [1, 2, 3, 4, 5, 6, 7],
    "weekdays" => [1, 2, 3, 4, 5],
    "weekends" => [6, 7],
    "monday" => [1],
    "tuesday" => [2],
    "wednesday" => [3],
    "thursday" => [4],
    "friday" => [5],
    "saturday" => [6],
    "sunday" => [7]
  }

  embedded_schema do
    field(:day, :string)
    field(:start_minute, :integer)
    field(:end_minute, :integer)
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:day, :start_minute, :end_minute])
  end

  @spec day_to_indexes(map()) :: [Calendar.day()]
  def day_to_indexes(%WorkingHours{day: day}) do
    Map.fetch!(@day_to_indexes, day)
  end
end
