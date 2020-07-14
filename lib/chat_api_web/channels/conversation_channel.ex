defmodule ChatApiWeb.ConversationChannel do
  use ChatApiWeb, :channel

  alias ChatApi.{Chat, Conversations}

  @impl true
  def join("conversation:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("conversation:" <> private_conversation_id, payload, socket) do
    IO.puts("Checking permission for conversation!")
    IO.inspect(payload)
    IO.inspect(private_conversation_id)

    if authorized?(payload, private_conversation_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (conversation:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    {:ok, message} = Chat.create_message(payload)
    result = ChatApiWeb.MessageView.render("message.json", message: message)

    broadcast(socket, "shout", result)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp authorized?(_payload, conversation_id) do
    IO.puts("Invoking `authorized?` method!")
    IO.inspect(conversation_id)
    IO.inspect(Conversations.get_conversation(conversation_id))

    case Conversations.get_conversation(conversation_id) do
      %Conversations.Conversation{} -> true
      _ -> false
    end
  end
end
