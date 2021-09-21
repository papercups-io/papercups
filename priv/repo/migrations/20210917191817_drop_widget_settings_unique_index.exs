defmodule ChatApi.Repo.Migrations.DropWidgetSettingsUniqueIndex do
  use Ecto.Migration

  def up do
    drop_if_exists(unique_index(:widget_settings, [:account_id]))
    create(unique_index(:widget_settings, [:account_id, :inbox_id]))
  end

  def down do
    drop(unique_index(:widget_settings, [:account_id, :inbox_id]))
    create(unique_index(:widget_settings, [:account_id]))
  end
end
