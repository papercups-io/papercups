defmodule ChatApi.Repo.Migrations.AddHostNameToWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add(:last_seen_at, :utc_datetime)
      add(:host, :string)
      add(:pathname, :string)
    end
  end
end
