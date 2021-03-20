defmodule ChatApi.Workers.SendSlackReminders do
  alias ChatApi.{Conversations, Conversations.Conversation, Users, Users.User}

  @spec list_forgotten_conversations :: [ChatApi.Conversations.Conversation.t()]
  def list_forgotten_conversations() do
    Conversations.list_forgotten_conversations(24)
  end

  @spec find_slackable_users([Conversation.t()]) :: [User.t()]
  def find_slackable_users(conversations) do
    conversations
    |> Enum.map(& &1.assignee_id)
    |> Enum.reject(&is_nil/1)
    |> Users.list_slackable_users_from_ids()
  end
end
