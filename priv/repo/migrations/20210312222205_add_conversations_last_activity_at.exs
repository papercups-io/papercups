defmodule ChatApi.Repo.Migrations.AddConversationsLastActivityAt do
  use Ecto.Migration

  def up do
    alter table(:conversations) do
      add(:last_activity_at, :utc_datetime)
    end

    execute("""
    UPDATE conversations SET last_activity_at = subquery.recent_inserted_at
    FROM (SELECT conversation_id, MAX(inserted_at) AS recent_inserted_at FROM messages GROUP BY conversation_id) AS subquery
    WHERE subquery.conversation_id = conversations.id;
    """)
  end

  def down do
    alter table(:conversations) do
      remove(:last_activity_at)
    end
  end
end
