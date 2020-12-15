defmodule ChatApi.Repo.Migrations.AddTypeToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add(:message_type, :string)
      add(:priv, :boolean)
    end
  end
end
