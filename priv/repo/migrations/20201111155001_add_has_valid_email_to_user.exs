defmodule ChatApi.Repo.Migrations.AddHasValidEmailToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:has_valid_email, :boolean)
    end
  end
end
