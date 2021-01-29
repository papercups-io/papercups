defmodule ChatApi.Repo.Migrations.MakeMessageBodyOptional do
  use Ecto.Migration

  import Ecto.Query, warn: false

  require Logger

  alias ChatApi.Repo
  alias ChatApi.Messages.Message

  def up do
    alter table(:messages) do
      modify(:body, :text, null: true)
    end
  end

  def down do
    {n, _} =
      Message
      |> where([m], is_nil(m.body))
      |> Repo.update_all(set: [body: ""])

    Logger.info("Updated #{n} messages with nil body")

    alter table(:messages) do
      modify(:body, :text, null: false)
    end
  end
end
