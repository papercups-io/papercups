defmodule ChatApi.Repo.Migrations.ConversationBelongsToUser do
  use Ecto.Migration

  def up do
    alter table(:conversations) do
      add :assignee_id, references(:users), null: true
      modify :status, :string, default: "open"
      add :priority, :string, default: "not_priority"
      add :read, :boolean, default: false
    end
  end

  def down do
    alter table(:conversations) do
      remove :assignee_id, references(:users), null: true
      modify :status, :string, default: "open"
      remove :priority, :string, default: "not_priority"
      remove :read, :boolean, default: false
    end
  end
end
