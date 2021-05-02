defmodule ChatApi.Repo.Migrations.UpdateCustomersLastSeenAt do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE customers SET last_seen_at = last_seen WHERE last_seen_at IS null;
    """)
  end

  def down do
    nil
  end
end
