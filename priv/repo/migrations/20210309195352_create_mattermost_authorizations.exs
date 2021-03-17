defmodule ChatApi.Repo.Migrations.CreateMattermostAuthorizations do
  use Ecto.Migration

  def change do
    create table(:mattermost_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:access_token, :string, null: false)
      add(:refresh_token, :string)
      add(:bot_token, :string)
      add(:verification_token, :string)
      add(:mattermost_url, :string)
      add(:channel_id, :string)
      add(:channel_name, :string)
      add(:team_id, :string)
      add(:team_domain, :string)
      add(:webhook_url, :string)
      add(:scope, :string)
      add(:metadata, :map)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create(index(:mattermost_authorizations, [:account_id]))
    create(index(:google_authorizations, [:account_id]))

    create(index(:mattermost_authorizations, [:user_id]))
    create(index(:google_authorizations, [:user_id]))
  end
end
