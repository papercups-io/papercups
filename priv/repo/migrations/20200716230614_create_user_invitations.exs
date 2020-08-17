defmodule ChatApi.Repo.Migrations.CreateUserInvitations do
  use Ecto.Migration

  def change do
    create table(:user_invitations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:account_id, references(:accounts, type: :uuid), null: false)
      add(:expires_at, :utc_datetime, null: false)

      timestamps()
    end

    create(index(:user_invitations, [:account_id]))
  end
end
