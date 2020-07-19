defmodule ChatApi.Repo.Migrations.AddEmailSubscriptionToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:email_alert_on_new_message, :boolean, default: false)
    end
  end
end
