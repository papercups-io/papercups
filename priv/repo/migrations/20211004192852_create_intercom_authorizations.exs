defmodule ChatApi.Repo.Migrations.CreateIntercomAuthorizations do
  use Ecto.Migration

  def change do
    create table(:intercom_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:access_token, :string, null: false)
      add(:token_type, :string)
      add(:scope, :string)
      add(:metadata, :map)

      add(:user_id, references(:users, on_delete: :delete_all))

      add(:account_id, references(:accounts, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      timestamps()
    end

    create(index(:intercom_authorizations, [:account_id]))
    create(index(:intercom_authorizations, [:user_id]))

    alter table(:messages) do
      add(:content_type, :string, default: "text")
    end

    alter table(:notes) do
      add(:content_type, :string, default: "text")
    end
  end
end
