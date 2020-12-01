defmodule ChatApi.Repo.Migrations.AddHideWidgetOutsideWorkingHoursToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :hide_widget_outside_working_hours, :boolean
    end
  end
end
