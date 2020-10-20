defmodule ChatApi.Repo.Migrations.ChangeCurrentUrlAndPathnameFieldsTypeToText do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      modify :current_url, :text
      modify :pathname, :text
    end
  end
end
