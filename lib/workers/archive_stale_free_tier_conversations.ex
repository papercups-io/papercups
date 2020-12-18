defmodule ChatApi.Workers.ArchiveStaleFreeTierConversations do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Conversations

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    conversations_query = Conversations.query_free_tier_conversations_inactive_for(days: 30)
    {n, _} = Conversations.archive_conversations(conversations_query)

    Logger.info("Archived #{n} stale conversations from free tier accounts")

    :ok
  end
end
