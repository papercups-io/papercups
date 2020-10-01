defmodule ChatApi.Repo.Migrations.AddWorkingHoursToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:time_zone, :string)
      add(:working_hours, {:array, :map}, default: [])
    end
  end
end
