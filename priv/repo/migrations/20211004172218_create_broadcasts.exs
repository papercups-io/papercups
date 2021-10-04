defmodule ChatApi.Repo.Migrations.CreateBroadcasts do
  use Ecto.Migration

  def change do
    create table(:broadcasts, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:description, :string)
      add(:subject, :string)
      add(:state, :string, null: false, default: "unstarted")
      add(:started_at, :utc_datetime)
      add(:finished_at, :utc_datetime)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)
      add(:message_template_id, references(:message_templates, type: :uuid, on_delete: :nothing))

      timestamps()
    end

    create index(:broadcasts, [:account_id])
    create index(:broadcasts, [:message_template_id])
    create(unique_index(:broadcasts, [:name]))

    create table(:broadcast_customers, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:state, :string, null: false, default: "unsent")
      add(:sent_at, :utc_datetime)
      add(:delivered_at, :utc_datetime)
      add(:seen_at, :utc_datetime)
      add(:bounced_at, :utc_datetime)
      add(:failed_at, :utc_datetime)
      add(:unsubscribed_at, :utc_datetime)
      add(:metadata, :map)

      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      add(:broadcast_id, references(:broadcasts, type: :uuid, on_delete: :delete_all), null: false)

      add(:customer_id, references(:customers, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create index(:broadcast_customers, [:account_id])
    create index(:broadcast_customers, [:broadcast_id])
    create index(:broadcast_customers, [:customer_id])
    create(unique_index(:broadcast_customers, [:account_id, :broadcast_id, :customer_id]))
  end
end
