defmodule ChatApi.Repo.Migrations.CreateHubspotAuthorizations do
  use Ecto.Migration

  def change do
    create table(:hubspot_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:access_token, :string, null: false)
      add(:refresh_token, :string, null: false)
      add(:expires_at, :utc_datetime)
      add(:token_type, :string)
      add(:hubspot_app_id, :integer)
      add(:hubspot_portal_id, :integer)
      add(:scope, :string)
      add(:metadata, :map)

      add(:user_id, references(:users, on_delete: :delete_all))

      add(:account_id, references(:accounts, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      timestamps()
    end

    create(index(:hubspot_authorizations, [:user_id]))
    create(index(:hubspot_authorizations, [:account_id]))
  end
end
