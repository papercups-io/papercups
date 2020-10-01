defmodule ChatApi.Repo.Migrations.AddTimeZoneToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add(:time_zone, :string)
    end
  end
end
