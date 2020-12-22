defmodule ChatApi.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :external_id, :string
      add :website_url, :string
      add :description, :string
      add :logo_image_url, :string
      add :industry, :string
      add :slack_channel_id, :string
      add :metadata, :map

      add :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id),
        null: false

      timestamps()
    end

    alter table(:customers) do
      add :company_id, references(:companies, on_delete: :nothing, type: :binary_id)
    end

    create index(:companies, [:account_id])
    create index(:customers, [:company_id])
  end
end
