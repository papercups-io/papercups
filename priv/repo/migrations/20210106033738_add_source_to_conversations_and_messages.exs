defmodule ChatApi.Repo.Migrations.AddSourceToConversationsAndMessages do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add(:source, :string, default: "chat")
      add(:metadata, :map)
    end

    alter table(:messages) do
      add(:source, :string, default: "chat")
      add(:metadata, :map)
    end
  end
end
