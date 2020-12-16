defmodule ChatApi.Repo.Migrations.AddTypeToSlackAuthorizations do
  use Ecto.Migration

  def change do
    alter table(:slack_authorizations) do
      # At some point, it may make sense to make this an enum ("reply", "support")
      add(:type, :string, default: "reply")
    end
  end
end
