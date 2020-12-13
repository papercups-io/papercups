defmodule ChatApi.Workers.ArchiveFreeTierConversations do
  use Oban.Worker, queue: :events

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => _id} = _args}) do
    Logger.info("archived #{} stale (old) freetier conversations")
  end
end
