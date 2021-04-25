defmodule ChatApi.Repo.Migrations.AddSubjectToConversationsAndMessages do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add(:subject, :string)
    end

    alter table(:messages) do
      add(:subject, :string)
    end
  end
end
