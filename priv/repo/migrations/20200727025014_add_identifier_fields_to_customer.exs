defmodule ChatApi.Repo.Migrations.AddIdentifierFieldsToCustomer do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add(:email, :string)
      add(:name, :string)
      add(:phone, :string)
      add(:external_id, :string)

      add(:browser, :string)
      add(:browser_version, :string)
      add(:browser_language, :string)
      add(:os, :string)
      add(:ip, :string)
    end
  end
end
