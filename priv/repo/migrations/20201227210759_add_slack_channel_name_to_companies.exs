defmodule ChatApi.Repo.Migrations.AddSlackChannelNameToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :slack_channel_name, :string
    end
  end
end
