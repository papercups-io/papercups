defmodule ChatApi.Repo.Migrations.AddSlackTeamToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add(:slack_team_id, :string)
      add(:slack_team_name, :string)
    end

    alter table(:slack_conversation_threads) do
      # TODO: try to backfill these fields based on existing data
      add(:slack_team, :string)

      add(
        :slack_authorization_id,
        references(:slack_authorizations, type: :uuid, on_delete: :nothing)
      )
    end

    create index(:slack_conversation_threads, [:slack_authorization_id])
  end
end
