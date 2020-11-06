defmodule ChatApi.Workers.ArchiveConversations do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.{Conversations, Repo}

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    archived_conversations = Conversations.query_conversations_closed_for(days: 14)

    {n, nil} =
      archived_conversations
      |> Conversations.archive_conversations()

    archived_conversations
    |> Repo.all()
    |> Conversations.Helpers.send_multiple_archived_updates()

    Logger.info("Archived #{n} conversations")

    :ok
  end
end
