defmodule ChatApi.Repo.Migrations.AddMoreCustomerMetadata do
  use Ecto.Migration

  def change do
    # Example:
    #   browser: "Chrome"
    #   browser_version: 84
    #   current_url: "http://localhost:3000/"
    #   host: "localhost:3000"
    #   lib: "web"
    #   os: "Mac OS X"
    #   pathname: "/"
    #   screen_height: 1440
    #   screen_width: 2560
    #   last_seen_at: 1596831515.668

    alter table(:customers) do
      add(:last_seen_at, :utc_datetime)
      add(:current_url, :string)
      add(:host, :string)
      add(:pathname, :string)
      add(:screen_height, :integer)
      add(:screen_width, :integer)
      add(:lib, :string)
    end
  end
end
