defmodule ChatApi.Repo.Migrations.AddConversationIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all))
    end

    create(index(:messages, [:conversation_id]))
  end
end
