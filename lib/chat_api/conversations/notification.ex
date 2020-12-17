defmodule ChatApi.Conversations.Notification do
  @moduledoc """
  Notification handlers for conversations
  """

  alias ChatApi.Conversations.Conversation

  def broadcast_conversation_to_admin!(
        %Conversation{id: conversation_id, account_id: account_id} = conversation
      ) do
    ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:created", %{
      "id" => conversation_id
    })

    conversation
  end

  def broadcast_conversation_to_customer!(
        %Conversation{id: conversation_id, customer_id: customer_id} = conversation
      ) do
    ChatApiWeb.Endpoint.broadcast!(
      "conversation:lobby:" <> customer_id,
      "conversation:created",
      %{
        "id" => conversation_id
      }
    )

    conversation
  end
end
