defmodule ChatApiWeb.ConversationChannel do
  use ChatApiWeb, :channel

  alias ChatApi.{Accounts, Chat, Conversations, Emails}

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

      {:ok,
       assign(
         socket,
         :conversation,
         ChatApiWeb.ConversationView.render("basic.json", conversation: conversation)
       )}
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
    case socket.assigns do
      %{conversation: conversation} ->
        %{id: conversation_id, account_id: account_id} = conversation

        msg =
          Map.merge(payload, %{"conversation_id" => conversation_id, "account_id" => account_id})

        {:ok, message} = Chat.create_message(msg)
        Conversations.mark_conversation_unread(conversation_id)
        result = ChatApiWeb.MessageView.render("message.json", message: message)

        # TODO: double check that this still works as expected
        broadcast(socket, "shout", result)

        # TODO: maybe do these in an "after_send" hook or something more async,
        # since this notification logic probably shouldn't live in here.
        account = Accounts.get_account!(account_id)
        Emails.send_email_alerts(account.users, message.body, conversation_id)

        ChatApi.Slack.send_conversation_message_alert(conversation_id, message.body,
          type: "customer"
        )

      _ ->
        broadcast(socket, "shout", payload)
    end

    {:noreply, socket}
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
