defmodule ChatApi.Repo.Migrations.AddMetadataToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add(:metadata, :map)
    end
  end
end
