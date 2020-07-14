defmodule ChatApi.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:status, :string)

      timestamps()
    end
  end
end
