defmodule ChatApiWeb.ConversationChannel do
  use ChatApiWeb, :channel

  alias ChatApiWeb.Presence
  alias ChatApi.{Messages, Conversations, Emails, EventSubscriptions}

  @impl true
  def join("conversation:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
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
          online_at: inspect(System.system_time(:second))
        })

      topic = "notification:" <> account_id

      # Track the presence of this customer for the given account,
      # so agents can see the "online" status in the dashboard
      {:ok, _} =
        Presence.track(self(), topic, key, %{
          online_at: inspect(System.system_time(:second))
        })

      push(socket, "presence_state", Presence.list(socket))
      ChatApiWeb.Endpoint.broadcast!(topic, "presence_state", Presence.list(topic))
    end

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (conversation:lobby).
  def handle_in("shout", payload, socket) do
    with %{conversation: conversation} <- socket.assigns,
         %{id: conversation_id, account_id: account_id} <- conversation,
         {:ok, message} <-
           payload
           |> Map.merge(%{"conversation_id" => conversation_id, "account_id" => account_id})
           |> Messages.create_message(),
         message <- Messages.get_message!(message.id) do
      broadcast_new_message(socket, message)
    else
      _ ->
        broadcast(socket, "shout", payload)
    end

    {:noreply, socket}
  end

  defp send_message_alerts(message) do
    %{conversation_id: conversation_id, account_id: account_id, body: body} = message
    # TODO: how should we handle errors here?
    ChatApi.Slack.send_conversation_message_alert(conversation_id, body, type: :customer)

    # TODO: maybe do these in an "after_send" hook or something more async,
    # since this notification logic probably shouldn't live in here.
    Emails.send_new_message_alerts(body, account_id, conversation_id)
  end

  defp send_webhook_notifications(account_id, payload) do
    EventSubscriptions.notify_event_subscriptions(account_id, %{
      "event" => "message:created",
      "payload" => payload
    })
  end

  defp broadcast_conversation_update(message) do
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
  end

  defp broadcast_new_message(socket, message) do
    broadcast_conversation_update(message)

    %{account_id: account_id} = message
    json = ChatApiWeb.MessageView.render("expanded.json", message: message)
    broadcast(socket, "shout", json)

    # Handling async for now
    Task.start(fn ->
      send_message_alerts(message)
    end)

    Task.start(fn ->
      send_webhook_notifications(account_id, json)
    end)
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp authorized?(_payload, conversation_id) do
    case Conversations.get_conversation(conversation_id) do
      %Conversations.Conversation{} -> true
      _ -> false
    end
  end
end
