defmodule ChatApi.Repo.Migrations.CreateGoogleAuthorizations do
  use Ecto.Migration

  def change do
    create table(:google_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      # e.g. gmail, sheets, etc
      add(:client, :string)
      add(:access_token, :string)
      add(:refresh_token, :string, null: false)
      add(:token_type, :string)
      add(:expires_at, :integer)
      add(:scope, :string)

      add(:account_id, references(:accounts, type: :uuid), null: false, on_delete: :delete_all)
      add(:user_id, references(:users), null: false, on_delete: :delete_all)

      timestamps()
    end
  end
end
