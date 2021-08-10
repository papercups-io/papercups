defmodule ChatApi.Repo.Migrations.AddExpoPushTokenToUserSettings do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add(:expo_push_token, :string)
    end
  end
end
