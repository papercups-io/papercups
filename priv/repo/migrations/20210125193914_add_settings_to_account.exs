defmodule ChatApi.Repo.Migrations.AddSettingsToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      # NB: eventually it may make sense to have a separate `account_settings` table,
      # but for now I'm not sure it necessarily needs to be relational?
      add(:settings, :map)
    end
  end
end
