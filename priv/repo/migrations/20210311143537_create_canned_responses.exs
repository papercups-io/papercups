defmodule ChatApi.Repo.Migrations.CreateCannedResponses do
  use Ecto.Migration

  def change do
    create table(:canned_responses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :content, :text, null: false

      add :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps()
    end

    create index(:canned_responses, [:account_id])
    create unique_index(:canned_responses, [:name, :account_id])
  end
end
