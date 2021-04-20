defmodule ChatApi.Repo.Migrations.CreateGithubAuthorizations do
  use Ecto.Migration

  def change do
    create table(:github_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:access_token, :string)
      add(:access_token_expires_at, :utc_datetime)
      add(:refresh_token, :string)
      add(:refresh_token_expires_at, :utc_datetime)
      add(:token_type, :string)
      add(:scope, :string)
      add(:github_installation_id, :string)
      add(:metadata, :map)

      add(:account_id, references(:accounts, type: :uuid), null: false, on_delete: :delete_all)
      add(:user_id, references(:users), null: false, on_delete: :delete_all)

      timestamps()
    end

    create(index(:github_authorizations, [:account_id]))
    create(index(:github_authorizations, [:user_id]))
  end
end
