defmodule ChatApi.Workers.ArchiveConversations do
  use Oban.Worker, queue: :default

  alias ChatApi.Conversations

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Conversations.list_conversations_to_archive()
    |> Enum.each(&Conversations.archive_conversation/1)
  end
end
