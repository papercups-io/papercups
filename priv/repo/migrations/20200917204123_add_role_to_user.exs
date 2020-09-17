defmodule ChatApi.Repo.Migrations.AddRoleToUser do
  use Ecto.Migration

  alias ChatApi.{Users, Repo}

  def change do
    alter table(:users) do
      add(:role, :string, default: "user")
    end

    # Default all current users to admin for now
    execute(
      fn -> Repo.update_all(Users.User, set: [role: "admin"]) end,
      fn -> nil end
    )
  end
end
