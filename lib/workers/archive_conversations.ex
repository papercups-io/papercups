defmodule ChatApi.Workers.ArchiveConversations do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Conversations

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    {n, nil} =
      Conversations.query_conversations_closed_for(days: 14)
      |> Conversations.archive_conversations()

    Logger.info("Archived #{n} conversations")

    :ok
  end
end
