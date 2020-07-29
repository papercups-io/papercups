defmodule ChatApi.Repo.Migrations.CreateWidgetSettings do
  use Ecto.Migration

  def change do
    create table(:widget_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string)
      add(:subtitle, :string)
      add(:color, :string)
      add(:account_id, references(:accounts, type: :uuid), null: false)

      timestamps()
    end

    create(unique_index(:widget_settings, [:account_id]))
  end
end
