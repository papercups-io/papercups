defmodule ChatApi.Repo.Migrations.ChangePathnameFieldTypeToText do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      modify :pathname, :text
    end
  end
end
