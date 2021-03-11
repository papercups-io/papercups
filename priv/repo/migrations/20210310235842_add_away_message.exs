defmodule ChatApi.Repo.Migrations.AddAwayMessage do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add(:away_message, :text)
    end
  end
end
