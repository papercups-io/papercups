defmodule ChatApi.Repo.Migrations.AddTypeToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:type, :string)
      add(:private, :boolean)
    end
  end
end
