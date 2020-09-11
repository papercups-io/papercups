defmodule ChatApi.Repo.Migrations.AddEmailConfirmationAndPasswordResetToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:email_confirmation_token, :string)
      add(:email_confirmed_at, :utc_datetime)
      add(:password_reset_token, :string)
    end

    create(unique_index(:users, [:email_confirmation_token]))
    create(unique_index(:users, [:password_reset_token]))
  end
end
