defmodule ChatApi.Repo.Migrations.AddSlackUserIdToUserProfiles do
  use Ecto.Migration

  def change do
    alter table(:user_profiles) do
      add(:slack_user_id, :string)
    end
  end
end
