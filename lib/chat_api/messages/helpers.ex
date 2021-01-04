defmodule ChatApi.Messages.Helpers do
  @moduledoc """
  Helpers for Messages context
  """

  alias ChatApi.Conversations
  alias ChatApi.Messages.Message

  @spec get_conversation_topic(Message.t()) :: binary()
  def get_conversation_topic(%{conversation_id: conversation_id} = _message),
    do: "conversation:" <> conversation_id

  @spec format(Message.t()) :: map()
  def format(%Message{} = message),
    do: ChatApiWeb.MessageView.render("expanded.json", message: message)

  @spec get_message_type(Message.t()) :: atom()
  def get_message_type(%Message{customer_id: nil}), do: :agent
  def get_message_type(%Message{user_id: nil}), do: :customer
  def get_message_type(_message), do: :unknown

  @spec handle_post_creation_conversation_updates(Message.t()) :: Message.t()
  def handle_post_creation_conversation_updates(%Message{} = message) do
    message
    |> build_conversation_updates()
    |> update_and_broadcast_to_admin(message)

    message
  end

  @spec build_conversation_updates(Message.t()) :: map()
  def build_conversation_updates(%Message{} = message) do
    %{}
    |> build_first_reply_updates(message)
    |> build_message_type_updates(message)
  end

  @spec build_first_reply_updates(map(), Message.t()) :: map()
  defp build_first_reply_updates(
         updates,
         %Message{
           conversation_id: conversation_id,
           user_id: assignee_id
         }
       ) do
    if Conversations.count_agent_replies(conversation_id) == 1 do
      Map.merge(updates, %{assignee_id: assignee_id})
    else
      updates
    end
  end

  @spec build_message_type_updates(map(), Message.t()) :: map()
  defp build_message_type_updates(updates, %Message{} = message) do
    case get_message_type(message) do
      # If agent responded, conversation should be marked as "read"
      :agent -> Map.merge(updates, %{read: true})
      _ -> updates
    end
  end

  @spec update_and_broadcast_to_admin(map(), Message.t()) :: any()
  defp update_and_broadcast_to_admin(
         updates,
         %Message{
           account_id: account_id,
           conversation_id: conversation_id
         } = _message
       ) do
    # TODO: DRY up this logic with other places we do conversation updates w/ broadcasting?
    {:ok, conversation} =
      conversation_id
      |> Conversations.get_conversation!()
      |> Conversations.update_conversation(updates)

    ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:updated", %{
      "id" => conversation_id,
      "updates" => ChatApiWeb.ConversationView.render("basic.json", conversation: conversation)
    })
  end
end
