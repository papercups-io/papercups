defmodule ChatApi.Workers.MessageCreatedActions do
  use Oban.Worker, queue: :events
  alias ChatApi.Conversations
  alias ChatApi.Messages

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    message = Messages.get_message!(id)

    with {:ok, _} <- Conversations.mark_activity(message.conversation_id) do
      :ok
    else
      err -> err
    end
  end
end
