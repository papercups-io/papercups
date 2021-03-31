defmodule ChatApi.Conversations.Notification do
  @moduledoc """
  Notification handlers for conversations
  """

  alias ChatApi.Conversations.{Conversation, Helpers}
  alias ChatApi.EventSubscriptions

  require Logger

  @spec broadcast_new_conversation_to_admin!(Conversation.t()) :: Conversation.t()
  def broadcast_new_conversation_to_admin!(
        %Conversation{id: conversation_id, account_id: account_id} = conversation
      ) do
    Logger.info("Sending conversation notification: broadcast_new_conversation_to_admin!")

    ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:created", %{
      "id" => conversation_id
    })

    conversation
  end

  @spec broadcast_new_conversation_to_customer!(Conversation.t()) :: Conversation.t()
  def broadcast_new_conversation_to_customer!(
        %Conversation{id: conversation_id, customer_id: customer_id} = conversation
      ) do
    Logger.info("Sending conversation notification: broadcast_new_conversation_to_customer!")

    ChatApiWeb.Endpoint.broadcast!(
      "conversation:lobby:" <> customer_id,
      "conversation:created",
      %{
        "id" => conversation_id
      }
    )

    conversation
  end

  @spec broadcast_conversation_update_to_admin!(Conversation.t()) :: Conversation.t()
  def broadcast_conversation_update_to_admin!(
        %Conversation{id: conversation_id, account_id: account_id} = conversation
      ) do
    Logger.info("Sending conversation notification: broadcast_conversation_update_to_admin!")

    ChatApiWeb.Endpoint.broadcast!(
      "notification:" <> account_id,
      "conversation:updated",
      %{
        "id" => conversation_id,
        "updates" => Helpers.format(conversation)
      }
    )

    conversation
  end

  @spec notify(Conversation.t(), atom(), keyword()) :: Conversation.t()
  def notify(conversation, type, opts \\ [])

  def notify(%Conversation{account_id: account_id} = conversation, :webhooks, event: event) do
    Logger.info("Sending conversation notification: :webhooks")

    Task.start(fn ->
      EventSubscriptions.notify_event_subscriptions(account_id, %{
        "event" => event,
        "payload" => Helpers.format(conversation)
      })
    end)

    conversation
  end

  def notify(%Conversation{} = conversation, :slack, _opts) do
    Logger.info("Sending conversation notification: :slack")

    Task.start(fn ->
      Helpers.broadcast_conversation_updates_to_slack(conversation)
    end)

    conversation
  end
end
