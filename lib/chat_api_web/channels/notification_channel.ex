defmodule ChatApiWeb.NotificationChannel do
  use ChatApiWeb, :channel

  alias Phoenix.Socket.Broadcast
  alias ChatApi.Chat

  @impl true
  def join("notification:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("notification:" <> _account_id, %{"ids" => ids}, socket) do
    topics = for conversation_id <- ids, do: "conversation:#{conversation_id}"

    {:ok,
     socket
     |> assign(:topics, [])
     |> put_new_topics(topics)}
  end

  def handle_in("watch", %{"conversation_id" => id}, socket) do
    {:reply, :ok, put_new_topics(socket, ["conversation:#{id}"])}
  end

  def handle_in("unwatch", %{"conversation_id" => id}, _socket) do
    {:reply, :ok, ChatApiWeb.Endpoint.unsubscribe("conversation:#{id}")}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("shout", payload, socket) do
    IO.inspect(payload)

    {:ok, message} = Chat.create_message(payload)
    result = ChatApiWeb.MessageView.render("message.json", message: message)

    IO.inspect(result)

    broadcast(socket, "shout", result)
    # TODO: figure out exactly the difference between all these `broadcast` methods
    broadcast_from!(socket, "shout", result)

    case result do
      %{conversation_id: conversation_id} ->
        topic = "conversation:" <> conversation_id
        IO.puts("BROADCASTING!!!")
        ChatApiWeb.Endpoint.broadcast_from!(self(), topic, "shout", result)

      _ ->
        nil
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

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
