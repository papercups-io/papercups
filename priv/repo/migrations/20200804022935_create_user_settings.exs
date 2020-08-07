defmodule ChatApi.Repo.Migrations.CreateUserSettings do
  use Ecto.Migration

  def change do
    create table(:user_settings, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:email_alert_on_new_message, :boolean, default: false, null: false)

      add(:user_id, references(:users, type: :integer), null: false)

      timestamps()
    end

    create(unique_index(:user_settings, [:user_id]))
  end
end
