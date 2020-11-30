defmodule ChatApi.Repo.Migrations.CreatePersonalApiKeys do
  use Ecto.Migration

  def change do
    create table(:personal_api_keys, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:label, :string)
      add(:value, :string)
      add(:last_used_at, :utc_datetime)

      add(:user_id, references(:users, type: :integer, on_delete: :delete_all), null: false)
      add(:account_id, references(:accounts, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:personal_api_keys, [:account_id]))
    create(index(:personal_api_keys, [:user_id]))
    create(unique_index(:personal_api_keys, [:value]))
  end
end
