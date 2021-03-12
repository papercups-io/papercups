defmodule ChatApi.Repo.Migrations.CreateCannedResponses do
  use Ecto.Migration

  def change do
    create table(:canned_responses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :content, :text
      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create unique_index(:canned_responses, [:name, :account_id], name: :unique_name_per_account)

    create index(:canned_responses, [:account_id])
  end
end
