defmodule ChatApi.Repo.Migrations.AddTypeToGoogleAuthorizations do
  use Ecto.Migration

  def up do
    alter table(:google_authorizations) do
      # At some point, it may make sense to make this an enum ("personal", "support", etc)
      # Note that this is currently only used for the Gmail integration (i.e. not Google Sheets)
      add(:type, :string)
    end

    execute("""
    UPDATE google_authorizations SET type = 'support' WHERE scope = 'https://www.googleapis.com/auth/gmail.modify';
    """)

    execute("""
    UPDATE google_authorizations SET type = 'sheets' WHERE scope = 'https://www.googleapis.com/auth/spreadsheets';
    """)
  end

  def down do
    alter table(:google_authorizations) do
      remove(:type, :string)
    end
  end
end
