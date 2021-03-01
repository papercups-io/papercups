defmodule ChatApi.Repo.Migrations.AddMoreFieldsToWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add(:is_open_by_default, :boolean, default: false)
      add(:icon_variant, :string, default: "outlined")
      add(:custom_icon_url, :string)
      add(:iframe_url_override, :string)
      add(:email_input_placeholder, :string)
      add(:new_messages_notification_text, :string)
    end
  end
end
