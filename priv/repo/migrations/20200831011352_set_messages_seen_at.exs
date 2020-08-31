defmodule ChatApi.Repo.Migrations.SetMessagesSeenAt do
  use Ecto.Migration

  import Ecto.Query, warn: false

  alias ChatApi.{Messages, Repo}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message

  def up do
    Conversation
    |> preload(:messages)
    |> Repo.all()
    |> Enum.map(fn conv -> mark_messages_seen(conv) end)
  end

  def down do
    Repo.update_all(Message, set: [seen_at: nil])
  end

  defp mark_messages_seen(%{messages: messages}) do
    timestamp = most_recent_customer_message_timestamp(messages)

    mark_previous_messages_seen(timestamp, messages)
  end

  defp most_recent_customer_message_timestamp(messages) do
    messages
    |> Enum.sort_by(fn msg -> msg.inserted_at end, :desc)
    |> Enum.find(fn msg -> not is_nil(msg.customer_id) end)
    |> case do
      %{inserted_at: timestamp} -> timestamp
      _ -> nil
    end
  end

  defp mark_previous_messages_seen(timestamp, messages) do
    messages
    |> Enum.filter(fn msg -> msg.inserted_at < timestamp end)
    |> Enum.map(fn msg ->
      Messages.update_message(msg, %{seen_at: msg.inserted_at})
    end)
  end
end
