defmodule ChatApi.Repo.Migrations.AddCompanyLogoUrlToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:company_logo_url, :string)
    end
  end
end
