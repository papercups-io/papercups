defmodule ChatApi.Repo.Migrations.AddRepliedAtFieldToConversation do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add(:first_replied_at, :utc_datetime)
    end
  end
end
