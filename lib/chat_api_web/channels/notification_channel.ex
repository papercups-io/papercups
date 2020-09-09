defmodule ChatApiWeb.NotificationChannel do
  use ChatApiWeb, :channel

  alias ChatApiWeb.Presence
  alias Phoenix.Socket.Broadcast
  alias ChatApi.{Messages, Conversations, EventSubscriptions}

  require Logger

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
      {:ok, message} =
        payload
        |> Map.merge(%{"user_id" => user_id, "account_id" => account_id})
        |> Messages.create_message()

      message
      |> Map.get(:id)
      |> Messages.get_message!()
      |> broadcast_new_message()
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
         %{id: user_id, account_id: account_id} <- current_user do
      key = "user:" <> inspect(user_id)

      {:ok, _} =
        Presence.track(socket, key, %{
          online_at: inspect(System.system_time(:second)),
          user_id: user_id
        })

      push(socket, "presence_state", Presence.list(socket))

      # Add tracking to "account room" so we can check which agents are online
      {:ok, _} =
        Presence.track(self(), "room:" <> account_id, key, %{
          online_at: inspect(System.system_time(:second)),
          user_id: user_id
        })
    end

    {:noreply, socket}
  end

  defp send_message_alerts(message) do
    %{conversation_id: conversation_id, customer_id: customer_id, body: body} = message
    type = if is_nil(customer_id), do: :agent, else: :customer

    # TODO: how should we handle errors here?
    ChatApi.Slack.send_conversation_message_alert(conversation_id, body, type: type)
  end

  # TODO: DRY up with conversation channel
  defp send_webhook_notifications(account_id, payload) do
    EventSubscriptions.notify_event_subscriptions(account_id, %{
      "event" => "message:created",
      "payload" => payload
    })
  end

  defp enqueue_conversation_reply_email(message) do
    # Enqueue reply email to send in 2 mins if necessary
    schedule_in = 2 * 60

    # TODO: not sure the best way to handle this, but basically we want to only
    # enqueue the latest message to trigger an email if it remains unseen for 2 mins
    ChatApi.Workers.SendConversationReplyEmail.cancel_pending_jobs(message)

    %{message: message}
    |> ChatApi.Workers.SendConversationReplyEmail.new(schedule_in: schedule_in)
    |> Oban.insert()
  end

  defp broadcast_new_message(message) do
    json = ChatApiWeb.MessageView.render("expanded.json", message: message)
    %{conversation_id: conversation_id, account_id: account_id} = message
    topic = "conversation:" <> conversation_id

    # TODO: explain the difference between broadcast! and broadcast_from! and
    # why we use one vs the other here
    ChatApiWeb.Endpoint.broadcast!(topic, "shout", json)

    # TODO: perhaps more of this logic should be handled in an "after_insert"
    # on messages? (see https://blog.danielberkompas.com/2016/09/27/ecto-multi-services/)

    # Handling async for now
    Task.start(fn ->
      send_message_alerts(message)
    end)

    Task.start(fn ->
      send_webhook_notifications(account_id, json)
    end)

    Task.start(fn ->
      enqueue_conversation_reply_email(json)
    end)
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
