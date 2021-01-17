defmodule ChatApi.Repo.Migrations.AddPrivateNoteFieldsToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      # Can be "reply" or "note" at the moment
      add(:type, :string, default: "reply")
      add(:private, :boolean, default: false)
    end
  end
end
