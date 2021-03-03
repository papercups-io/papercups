defmodule ChatApi.Repo.Migrations.FixOnDeleteCustomerAssociations do
  use Ecto.Migration

  def up do
    drop(constraint(:messages, "messages_customer_id_fkey"))
    drop(constraint(:conversations, "conversations_customer_id_fkey"))
    drop(constraint(:browser_sessions, "browser_sessions_customer_id_fkey"))

    alter table(:messages) do
      modify(:customer_id, references(:customers, type: :uuid, on_delete: :delete_all))
    end

    alter table(:conversations) do
      modify(:customer_id, references(:customers, type: :uuid, on_delete: :delete_all))
    end

    alter table(:browser_sessions) do
      modify(:customer_id, references(:customers, type: :uuid, on_delete: :delete_all))
    end
  end

  def down do
    drop(constraint(:messages, "messages_customer_id_fkey"))
    drop(constraint(:conversations, "conversations_customer_id_fkey"))
    drop(constraint(:browser_sessions, "browser_sessions_customer_id_fkey"))

    alter table(:messages) do
      modify(:customer_id, references(:customers, type: :uuid))
    end

    alter table(:conversations) do
      modify(:customer_id, references(:customers, type: :uuid))
    end

    alter table(:browser_sessions) do
      modify(:customer_id, references(:customers, type: :uuid))
    end
  end
end
