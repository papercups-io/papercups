defmodule ChatApi.Repo.Migrations.CreateSlackAuthorizations do
  use Ecto.Migration

  def change do
    create table(:slack_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:access_token, :string, null: false)
      add(:app_id, :string)
      add(:authed_user_id, :string)
      add(:bot_user_id, :string)
      add(:channel, :string)
      add(:channel_id, :string)
      add(:configuration_url, :string)
      add(:webhook_url, :string)
      add(:scope, :string)
      add(:team_id, :string)
      add(:team_name, :string)
      add(:token_type, :string)

      add(:account_id, references(:accounts, type: :uuid), null: false)

      timestamps()
    end
  end
end
