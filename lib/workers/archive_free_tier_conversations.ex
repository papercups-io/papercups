defmodule ChatApi.Workers.ArchiveFreeTierConversations do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Conversations

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    conversations_query = Conversations.find_freetier_conversations_old_by(days: 30)
    {n, _} = Conversations.archive_conversations(conversations_query)

    Logger.info("Archived #{n} old freetier conversations")

    :ok
  end
end
