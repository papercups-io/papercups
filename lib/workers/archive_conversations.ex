defmodule ChatApi.Workers.ArchiveConversations do
  @moduledoc """
  A worker that archives stale conversations (e.g. closed for more than 14 days)
  """

  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Conversations

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    query = Conversations.query_conversations_closed_for(days: 14)
    {n, nil} = Conversations.archive_conversations(query)

    # NB: commenting this out for now -- worried this might spam people with a
    # ton of messages since it's possible to have >100 stale conversations
    # query
    # |> Repo.all()
    # |> Conversations.Helpers.send_multiple_archived_updates()

    Logger.info("Archived #{n} conversations")

    :ok
  end
end
