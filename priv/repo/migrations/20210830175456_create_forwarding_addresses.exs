defmodule ChatApi.Repo.Migrations.CreateForwardingAddresses do
  use Ecto.Migration

  def change do
    create table(:forwarding_addresses, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:forwarding_email_address, :string, null: false)
      add(:source_email_address, :string)
      add(:state, :string)
      add(:description, :string)
      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:forwarding_addresses, [:forwarding_email_address]))
    create(index(:forwarding_addresses, [:account_id]))
  end
end
