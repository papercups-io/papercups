defmodule ChatApiWeb.NotificationChannel do
  use ChatApiWeb, :channel

  alias ChatApiWeb.Presence
  alias Phoenix.Socket.Broadcast
  alias ChatApi.{Messages, Conversations}

  @messages_limit_to_autoassign 1

  @impl true
  def join("notification:" <> account_id, %{"ids" => ids}, socket) do
    if authorized?(socket, account_id) do
      topics = for conversation_id <- ids, do: "conversation:#{conversation_id}"

      send(self(), :after_join)

      {:ok,
       socket
       |> assign(:topics, [])
       |> put_new_topics(topics)}
    else
      {:error, %{reason: "Unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("watch:one", %{"conversation_id" => id}, socket) do
    {:reply, :ok, put_new_topics(socket, ["conversation:#{id}"])}
  end

  def handle_in("watch:many", %{"conversation_ids" => ids}, socket) do
    topics = Enum.map(ids, fn id -> "conversation:#{id}" end)

    {:reply, :ok, put_new_topics(socket, topics)}
  end

  def handle_in("unwatch", %{"conversation_id" => id}, _socket) do
    {:reply, :ok, ChatApiWeb.Endpoint.unsubscribe("conversation:#{id}")}
  end

  def handle_in("read", %{"conversation_id" => id}, socket) do
    _conversation = Conversations.mark_conversation_read(id)

    {:reply, :ok, socket}
  end

  def handle_in("shout", payload, socket) do
    with %{current_user: current_user} <- socket.assigns,
         %{id: user_id, account_id: account_id} <- current_user do
      msg = Map.merge(payload, %{"user_id" => user_id, "account_id" => account_id})
      {:ok, message} = Messages.create_message(msg)
      message = Messages.get_message!(message.id)
      result = ChatApiWeb.MessageView.render("expanded.json", message: message)

      # If the received message is the first one sent by any company user, assign the conversation to the user
      if Messages.count_messages_sent_by_company_user_in_conversation(message.conversation_id) ==
           @messages_limit_to_autoassign do
        message.conversation_id
        |> Conversations.get_conversation!()
        |> Conversations.update_conversation(%{assignee_id: message.user_id})
      end

      # TODO: write doc explaining difference between push, broadcast, etc.
      push(socket, "shout", result)

      %{conversation_id: conversation_id} = result
      topic = "conversation:" <> conversation_id

      ChatApiWeb.Endpoint.broadcast_from!(self(), topic, "shout", result)
      ChatApi.Slack.send_conversation_message_alert(conversation_id, message.body, type: :agent)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{topic: topic, event: event, payload: payload}, socket) do
    case topic do
      "conversation:" <> conversation_id ->
        push(socket, event, Map.merge(payload, %{conversation_id: conversation_id}))

      _ ->
        push(socket, event, payload)
    end

    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    with %{current_user: current_user} <- socket.assigns,
         %{id: user_id} <- current_user do
      key = "user:" <> inspect(user_id)

      {:ok, _} =
        Presence.track(socket, key, %{
          online_at: inspect(System.system_time(:second))
        })

      push(socket, "presence_state", Presence.list(socket))
    end

    {:noreply, socket}
  end

  defp put_new_topics(socket, topics) do
    Enum.reduce(topics, socket, fn topic, acc ->
      topics = acc.assigns.topics

      if topic in topics do
        acc
      else
        :ok = ChatApiWeb.Endpoint.subscribe(topic)
        assign(acc, :topics, [topic | topics])
      end
    end)
  end

  defp authorized?(socket, account_id) do
    with %{current_user: current_user} <- socket.assigns,
         %{account_id: acct} <- current_user do
      acct == account_id
    else
      _ -> false
    end
  end
end
