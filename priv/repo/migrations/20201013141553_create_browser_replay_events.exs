defmodule ChatApi.Repo.Migrations.CreateBrowserReplayEvents do
  use Ecto.Migration

  def change do
    create table(:browser_replay_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:timestamp, :utc_datetime_usec)
      add(:event, :map)

      add(:account_id, references(:accounts, null: false, type: :uuid, on_delete: :delete_all))

      add(
        :browser_session_id,
        references(:browser_sessions, null: false, type: :uuid, on_delete: :delete_all)
      )

      timestamps()
    end

    create(index(:browser_replay_events, [:account_id]))
    create(index(:browser_replay_events, [:browser_session_id]))
  end
end
