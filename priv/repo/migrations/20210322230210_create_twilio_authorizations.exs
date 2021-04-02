defmodule ChatApi.Repo.Migrations.CreateTwilioAuthorizations do
  use Ecto.Migration

  def change do
    create table(:twilio_authorizations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:twilio_auth_token, :string, null: false)
      add(:twilio_account_sid, :string, null: false)
      add(:from_phone_number, :string, null: false)
      add(:metadata, :map)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create(index(:twilio_authorizations, [:account_id]))
    create(index(:twilio_authorizations, [:user_id]))
  end
end
