defmodule ChatApi.Repo.Migrations.CreateBrowserSessions do
  use Ecto.Migration

  def change do
    create table(:browser_sessions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:metadata, :map)
      add(:started_at, :utc_datetime)
      add(:finished_at, :utc_datetime)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:customer_id, references(:customers, type: :uuid))

      timestamps()
    end

    create(index(:browser_sessions, [:account_id]))
    create(index(:browser_sessions, [:customer_id]))
  end
end
