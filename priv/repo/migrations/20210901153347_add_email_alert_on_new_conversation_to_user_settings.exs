defmodule ChatApi.Repo.Migrations.AddEmailAlertOnNewConversationToUserSettings do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:email_alert_on_new_conversation, :boolean, default: false)
    end
  end
end
