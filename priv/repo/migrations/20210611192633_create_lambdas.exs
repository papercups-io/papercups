defmodule ChatApi.Repo.Migrations.CreateLambdas do
  use Ecto.Migration

  def change do
    create table(:lambdas, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:description, :string)
      add(:code, :text)
      add(:language, :string)
      add(:runtime, :string)
      add(:status, :string, default: "pending", null: false)
      add(:last_deployed_at, :utc_datetime)
      add(:last_executed_at, :utc_datetime)

      add(:lambda_function_name, :string)
      add(:lambda_function_handler, :string)
      add(:lambda_revision_id, :string)
      add(:lambda_last_update_status, :string)

      add(:metadata, :map)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))

      timestamps()
    end

    create(index(:lambdas, [:account_id]))
    create(index(:lambdas, [:creator_id]))
  end
end
