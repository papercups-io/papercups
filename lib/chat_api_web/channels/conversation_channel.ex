defmodule ChatApiWeb.ConversationChannel do
  use ChatApiWeb, :channel

  alias ChatApiWeb.Presence
  alias ChatApi.{Messages, Conversations}
  alias ChatApi.Messages.Message

  @impl true
  def join("conversation:lobby", _payload, socket) do
    {:ok, socket}
  end

  def join("conversation:lobby:" <> customer_id, _params, socket) do
    {:ok, assign(socket, :customer_id, customer_id)}
  end

  def join("conversation:" <> private_conversation_id, payload, socket) do
    if authorized?(payload, private_conversation_id) do
      conversation = Conversations.get_conversation!(private_conversation_id)

      socket =
        assign(
          socket,
          :conversation,
          ChatApiWeb.ConversationView.render("basic.json", conversation: conversation)
        )

      # If the payload includes a customer_id, we want to mark this customer
      # as "online" via Phoenix Presence in the :after_join hook
      case payload do
        %{"customer_id" => customer_id} ->
          send(self(), :after_join)
          {:ok, socket |> assign(:customer_id, customer_id)}

        _ ->
          {:ok, socket}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    with %{customer_id: customer_id, conversation: conversation} <- socket.assigns,
         %{account_id: account_id} <- conversation do
      key = "customer:" <> customer_id

      # Track the presence of this customer in the conversation
      {:ok, _} =
        Presence.track(socket, key, %{
          online_at: inspect(System.system_time(:second)),
          customer_id: customer_id
        })

      topic = "notification:" <> account_id

      # Track the presence of this customer for the given account,
      # so agents can see the "online" status in the dashboard
      {:ok, _} =
        Presence.track(self(), topic, key, %{
          online_at: inspect(System.system_time(:second)),
          customer_id: customer_id
        })

      push(socket, "presence_state", Presence.list(socket))
      ChatApiWeb.Endpoint.broadcast!(topic, "presence_state", Presence.list(topic))
    end

    {:noreply, socket}
  end

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("shout", payload, socket) do
    with %{conversation: conversation} <- socket.assigns,
         %{id: conversation_id, account_id: account_id} <- conversation,
         {:ok, message} <-
           payload
           |> Map.merge(%{"conversation_id" => conversation_id, "account_id" => account_id})
           |> Messages.create_message() do
      case Map.get(payload, "file_ids") do
        file_ids when is_list(file_ids) -> Messages.create_attachments(message, file_ids)
        _ -> nil
      end

      message = Messages.get_message!(message.id)

      broadcast_new_message(socket, message)
    else
      _ ->
        broadcast(socket, "shout", payload)
    end

    {:noreply, socket}
  end

  def handle_in("messages:seen", _payload, socket) do
    with %{conversation: conversation} <- socket.assigns,
         %{id: conversation_id} <- conversation do
      Conversations.mark_agent_messages_as_seen(conversation_id)
    end

    {:noreply, socket}
  end

  @spec broadcast_conversation_update!(Message.t()) :: Message.t()
  defp broadcast_conversation_update!(message) do
    %{conversation_id: conversation_id, account_id: account_id} = message
    # Mark as unread and ensure the conversation is open, since we want to
    # reopen a conversation if it received a new message after being closed.
    {:ok, conversation} =
      conversation_id
      |> Conversations.get_conversation!()
      |> Conversations.update_conversation(%{status: "open", read: false})

    ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:updated", %{
      "id" => conversation_id,
      "updates" => ChatApiWeb.ConversationView.render("basic.json", conversation: conversation)
    })

    message
  end

  @spec broadcast_to_admin_channel!(Message.t()) :: Message.t()
  defp broadcast_to_admin_channel!(%Message{account_id: account_id} = message) do
    ChatApiWeb.Endpoint.broadcast!(
      "notification:" <> account_id,
      "shout",
      Messages.Helpers.format(message)
    )

    message
  end

  @spec broadcast_new_message(any(), Message.t()) :: Message.t()
  defp broadcast_new_message(socket, message) do
    broadcast_conversation_update!(message)
    broadcast(socket, "shout", Messages.Helpers.format(message))
    broadcast_to_admin_channel!(message)

    message
    |> Messages.Notification.notify(:slack)
    # TODO: check if :slack_support_channel and :slack_company_channel are relevant
    |> Messages.Notification.notify(:slack_support_channel)
    |> Messages.Notification.notify(:slack_company_channel)
    |> Messages.Notification.notify(:new_message_email)
    |> Messages.Notification.notify(:webhooks)
  end

  # Add authorization logic here as required.
  @spec authorized?(any(), binary()) :: boolean()
  defp authorized?(_payload, conversation_id) do
    case Conversations.get_conversation(conversation_id) do
      %Conversations.Conversation{} -> true
      _ -> false
    end
  end
end
