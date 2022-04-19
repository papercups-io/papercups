defmodule ChatApi.Repo.Migrations.CreateGmailConversationThreads do
  use Ecto.Migration

  def change do
    create table(:gmail_conversation_threads, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:gmail_thread_id, :string, null: false)
      add(:gmail_initial_subject, :string)
      add(:last_gmail_message_id, :string)
      add(:last_gmail_history_id, :string)
      add(:last_synced_at, :utc_datetime)
      add(:metadata, :map)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      add(:conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    alter table(:google_authorizations) do
      add(:metadata, :map)
    end

    create(index(:gmail_conversation_threads, [:account_id]))
    create(index(:gmail_conversation_threads, [:conversation_id]))
  end
end
