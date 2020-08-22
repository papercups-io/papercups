defmodule ChatApi.Repo.Migrations.CreateEventSubscriptions do
  use Ecto.Migration

  def change do
    create table(:event_subscriptions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:webhook_url, :string)
      add(:verified, :boolean, default: false, null: false)
      add(:scope, :string)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all))

      timestamps()
    end

    create(index(:event_subscriptions, [:account_id]))
  end
end
