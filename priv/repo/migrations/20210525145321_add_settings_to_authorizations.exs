defmodule ChatApi.Repo.Migrations.AddSettingsToAuthorizations do
  use Ecto.Migration

  def change do
    alter table(:slack_authorizations) do
      add(:settings, :map)
    end

    alter table(:google_authorizations) do
      add(:settings, :map)
    end

    alter table(:github_authorizations) do
      add(:settings, :map)
    end

    alter table(:twilio_authorizations) do
      add(:settings, :map)
    end

    alter table(:mattermost_authorizations) do
      add(:settings, :map)
    end
  end
end
