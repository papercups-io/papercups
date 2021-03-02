defmodule ChatApi.Repo.Migrations.AddIsBrandingHiddenToWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add(:is_branding_hidden, :boolean, default: false)
    end
  end
end
