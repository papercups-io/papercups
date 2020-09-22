defmodule ChatApi.Repo.Migrations.AddDisabledAtToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:disabled_at, :utc_datetime)
      add(:archived_at, :utc_datetime)
    end
  end
end
