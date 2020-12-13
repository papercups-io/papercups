defmodule ChatApi.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :text, null: false
      add :author_id, references(:users, on_delete: :nothing, type: :id), null: false

      add :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id),
        null: false

      add :customer_id, references(:customers, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps()
    end

    create index(:notes, [:author_id])
    create index(:notes, [:account_id])
    create index(:notes, [:customer_id])
  end
end
