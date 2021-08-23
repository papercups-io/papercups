defmodule ChatApi.Repo.Migrations.CreateMessageTemplates do
  use Ecto.Migration

  def change do
    create table(:message_templates, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:description, :string)
      add(:type, :string)
      add(:plain_text, :text)
      add(:raw_html, :text)
      add(:markdown, :text)
      add(:react_js, :text)
      add(:react_markdown, :text)
      add(:slack_markdown, :text)
      add(:default_variable_values, :map)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))

      timestamps()
    end

    create index(:message_templates, [:account_id])
  end
end
