defmodule ChatApi.Repo.Migrations.AddHideOutsideWorkingHoursToWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add :hide_outside_working_hours, :boolean
    end
  end
end
