defmodule ChatApi.Repo.Migrations.CreateMattermostConversationThreads do
  use Ecto.Migration

  def change do
    create table(:mattermost_conversation_threads, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:mattermost_channel_id, :string)
      add(:mattermost_post_root_id, :string)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      add(:conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(index(:mattermost_conversation_threads, [:account_id]))
    create(index(:slack_conversation_threads, [:account_id]))
    create(index(:mattermost_conversation_threads, [:conversation_id]))
    create(index(:slack_conversation_threads, [:conversation_id]))
  end
end
