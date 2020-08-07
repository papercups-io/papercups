defmodule ChatApi.Repo.Migrations.AddGreetingAndPlaceholderToWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add(:greeting, :string)
      add(:new_message_placeholder, :string)
      add(:base_url, :string)
    end
  end
end
