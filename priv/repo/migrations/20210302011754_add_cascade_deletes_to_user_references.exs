defmodule ChatApi.Repo.Migrations.AddCascadeDeletesToUserReferences do
  use Ecto.Migration

  def up do
    drop constraint("messages", "messages_user_id_fkey")
    drop constraint("conversations", "conversations_assignee_id_fkey")
    drop constraint("user_profiles", "user_profiles_user_id_fkey")
    drop constraint("user_settings", "user_settings_user_id_fkey")
    drop constraint("google_authorizations", "google_authorizations_user_id_fkey")
    drop constraint("tags", "tags_creator_id_fkey")
    drop constraint("conversation_tags", "conversation_tags_creator_id_fkey")
    drop constraint("notes", "notes_author_id_fkey")
    drop constraint("files", "files_user_id_fkey")

    alter table(:messages) do
      modify(:user_id, references(:users, on_delete: :delete_all))
    end

    alter table(:conversations) do
      modify(:assignee_id, references(:users, on_delete: :nilify_all))
    end

    alter table(:user_profiles) do
      modify(:user_id, references(:users, on_delete: :delete_all))
    end

    alter table(:user_settings) do
      modify(:user_id, references(:users, on_delete: :delete_all))
    end

    alter table(:google_authorizations) do
      modify(:user_id, references(:users, on_delete: :delete_all))
    end

    alter table(:tags) do
      modify(:creator_id, references(:users, on_delete: :nilify_all))
    end

    alter table(:conversation_tags) do
      modify(:creator_id, references(:users, on_delete: :nilify_all))
    end

    alter table(:notes) do
      modify(:author_id, references(:users, on_delete: :delete_all))
    end

    alter table(:files) do
      modify(:user_id, references(:users, on_delete: :delete_all))
    end
  end

  def down do
    drop constraint("messages", "messages_user_id_fkey")
    drop constraint("conversations", "conversations_assignee_id_fkey")
    drop constraint("user_profiles", "user_profiles_user_id_fkey")
    drop constraint("user_settings", "user_settings_user_id_fkey")
    drop constraint("google_authorizations", "google_authorizations_user_id_fkey")
    drop constraint("tags", "tags_creator_id_fkey")
    drop constraint("conversation_tags", "conversation_tags_creator_id_fkey")
    drop constraint("notes", "notes_author_id_fkey")
    drop constraint("files", "files_user_id_fkey")

    alter table(:messages) do
      modify(:user_id, references(:users, on_delete: :nothing))
    end

    alter table(:conversations) do
      modify(:assignee_id, references(:users, on_delete: :nothing))
    end

    alter table(:user_profiles) do
      modify(:user_id, references(:users, on_delete: :nothing))
    end

    alter table(:user_settings) do
      modify(:user_id, references(:users, on_delete: :nothing))
    end

    alter table(:google_authorizations) do
      modify(:user_id, references(:users, on_delete: :nothing))
    end

    alter table(:tags) do
      modify(:creator_id, references(:users, on_delete: :nothing))
    end

    alter table(:conversation_tags) do
      modify(:creator_id, references(:users, on_delete: :nothing))
    end

    alter table(:notes) do
      modify(:author_id, references(:users, on_delete: :nothing))
    end

    alter table(:files) do
      modify(:user_id, references(:users, on_delete: :nothing))
    end
  end
end
