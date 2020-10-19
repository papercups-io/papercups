defmodule ChatApi.Repo.Migrations.AddOnDeleteToConversationConstraintOnSlackConversationThreads do
  use Ecto.Migration

  def up do
    drop(
      constraint(:slack_conversation_threads, "slack_conversation_threads_conversation_id_fkey")
    )

    alter table(:slack_conversation_threads) do
      modify(:conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all),
        null: false
      )
    end
  end

  def down do
    drop(
      constraint(:slack_conversation_threads, "slack_conversation_threads_conversation_id_fkey")
    )

    alter table(:slack_conversation_threads) do
      modify(:conversation_id, references(:conversations, type: :uuid), null: false)
    end
  end
end
