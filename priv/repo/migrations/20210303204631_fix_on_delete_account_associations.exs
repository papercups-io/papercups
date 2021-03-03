defmodule ChatApi.Repo.Migrations.FixOnDeleteAccountAssociations do
  use Ecto.Migration

  def up do
    drop(constraint(:messages, "messages_account_id_fkey"))
    drop(constraint(:conversations, "conversations_account_id_fkey"))
    drop(constraint(:users, "users_account_id_fkey"))
    drop(constraint(:customers, "customers_account_id_fkey"))
    drop(constraint(:user_invitations, "user_invitations_account_id_fkey"))
    drop(constraint(:slack_conversation_threads, "slack_conversation_threads_account_id_fkey"))
    drop(constraint(:slack_authorizations, "slack_authorizations_account_id_fkey"))
    drop(constraint(:widget_settings, "widget_settings_account_id_fkey"))

    alter table(:messages) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:conversations) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:users) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:customers) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:user_invitations) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:slack_conversation_threads) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:slack_authorizations) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end

    alter table(:widget_settings) do
      modify(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
    end
  end

  def down do
    drop(constraint(:messages, "messages_account_id_fkey"))
    drop(constraint(:conversations, "conversations_account_id_fkey"))
    drop(constraint(:users, "users_account_id_fkey"))
    drop(constraint(:customers, "customers_account_id_fkey"))
    drop(constraint(:user_invitations, "user_invitations_account_id_fkey"))
    drop(constraint(:slack_conversation_threads, "slack_conversation_threads_account_id_fkey"))
    drop(constraint(:slack_authorizations, "slack_authorizations_account_id_fkey"))
    drop(constraint(:widget_settings, "widget_settings_account_id_fkey"))

    alter table(:messages) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:conversations) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:users) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:customers) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:user_invitations) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:slack_conversation_threads) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:slack_authorizations) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end

    alter table(:widget_settings) do
      modify(:account_id, references(:accounts, type: :uuid), null: false)
    end
  end
end
