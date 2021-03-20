defmodule ChatApi.Workers.SendSlackReminders do
  alias ChatApi.Conversations

  @spec list_forgotten_conversations :: [ChatApi.Conversations.Conversation.t()]
  def list_forgotten_conversations() do
    Conversations.list_forgotten_conversations(24)
  end
end
