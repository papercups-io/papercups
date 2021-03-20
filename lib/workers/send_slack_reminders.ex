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

  @spec group_conversations_by_slackable_user([Conversation.t()]) :: [
          {binary(), [Conversation.t()]}
        ]
  def group_conversations_by_slackable_user(conversations) do
    slackable_users = find_slackable_users(conversations)
    slackable_user_ids = slackable_users |> Enum.map(& &1.id)

    conversations
    |> Enum.filter(&(&1.assignee_id in slackable_user_ids))
    |> Enum.group_by(& &1.assignee_id)
    |> Map.to_list()
    |> Enum.map(fn {user_id, conversations} ->
      user = slackable_users |> Enum.find(&(&1.id == user_id))
      {user, conversations}
    end)
  end
end
