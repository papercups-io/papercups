defmodule ChatApi.Repo.Migrations.CreateIssues do
  use Ecto.Migration

  def change do
    create table(:issues, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string, null: false)
      add(:body, :text)
      add(:state, :string, null: false, default: "unstarted")
      add(:github_issue_url, :string)
      add(:finished_at, :utc_datetime)
      add(:closed_at, :utc_datetime)
      add(:metadata, :map)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))
      add(:assignee_id, references(:users, type: :integer))

      timestamps()
    end

    create(index(:issues, [:account_id]))
    create(index(:issues, [:creator_id]))
    create(index(:issues, [:assignee_id]))

    create table(:conversation_issues, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all))
      add(:issue_id, references(:issues, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))

      timestamps()
    end

    create(unique_index(:conversation_issues, [:account_id, :conversation_id, :issue_id]))
    create(index(:conversation_issues, [:account_id]))
    create(index(:conversation_issues, [:creator_id]))
    create(index(:conversation_issues, [:conversation_id]))
    create(index(:conversation_issues, [:issue_id]))

    create table(:customer_issues, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))
      add(:customer_id, references(:customers, type: :uuid, on_delete: :delete_all))
      add(:issue_id, references(:issues, type: :uuid, on_delete: :delete_all))
      add(:creator_id, references(:users, type: :integer))

      timestamps()
    end

    create(unique_index(:customer_issues, [:account_id, :customer_id, :issue_id]))
    create(index(:customer_issues, [:account_id]))
    create(index(:customer_issues, [:creator_id]))
    create(index(:customer_issues, [:customer_id]))
    create(index(:customer_issues, [:issue_id]))
  end
end
