defmodule ChatApi.Repo.Migrations.CreateSlackConversationThreads do
  use Ecto.Migration

  def change do
    create table(:slack_conversation_threads, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:slack_channel, :string)
      add(:slack_thread_ts, :string)
      add(:conversation_id, references(:conversations, type: :uuid), null: false)
      add(:account_id, references(:accounts, type: :uuid), null: false)

      timestamps()
    end
  end
end
