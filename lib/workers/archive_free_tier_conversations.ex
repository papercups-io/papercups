defmodule ChatApi.Workers.ArchiveFreeTierConversations do
  use Oban.Worker, queue: :events

  require Logger

  alias ChatApi.Conversations

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    conversations_query = Conversations.find_old_freetier_conversations(30)
    {n, _} = Conversations.archive_conversations(conversations_query)
    Logger.info("Archived #{n} old freetier conversations")
  end
end
