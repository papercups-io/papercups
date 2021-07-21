defmodule ChatApiWeb.NotificationChannel do
  use ChatApiWeb, :channel
  use Appsignal.Instrumentation.Decorators

  alias ChatApiWeb.Presence
  alias Phoenix.Socket.Broadcast
  alias ChatApi.{Messages, Conversations}
  alias ChatApi.Messages.Message

  require Logger

  @impl true
  def join("notification:" <> account_id, _payload, socket) do
    if authorized?(socket, account_id) do
      send(self(), :after_join)

      {:ok, socket}
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

  @decorate channel_action()
  def handle_in("read", %{"conversation_id" => id}, socket) do
    # TODO: the logic around marking conversations read may have to change with mentions,
    #       because we need to track who has actually seen the message and who hasn't...
    # TODO: we should probably handle the logic around counting unread messages on the server?

    case Conversations.mark_conversation_read(id) do
      {:ok, conversation} ->
        Conversations.Notification.notify(conversation, :webhooks, event: "conversation:updated")
        {_, nil} = Conversations.mark_mentions_seen(id, socket.assigns.current_user.id)

        {:reply, :ok, socket}

      {:error, error} ->
        {:reply, {:error, error}, socket}
    end
  end

  @decorate channel_action()
  def handle_in("shout", payload, socket) do
    with %{current_user: current_user} <- socket.assigns,
         %{id: user_id, account_id: account_id} <- current_user do
      {:ok, message} =
        payload
        |> Map.merge(%{"user_id" => user_id, "account_id" => account_id})
        |> Messages.create_message()

      case Map.get(payload, "mentioned_user_ids") do
        mentioned_user_ids when is_list(mentioned_user_ids) ->
          Messages.add_mentioned_users(message, mentioned_user_ids)

        _ ->
          nil
      end

      case Map.get(payload, "file_ids") do
        file_ids when is_list(file_ids) -> Messages.create_attachments(message, file_ids)
        _ -> nil
      end

      message.id
      |> Messages.get_message!()
      |> broadcast_new_message(socket)
      |> Messages.Helpers.handle_post_creation_hooks()
    end

    {:reply, :ok, socket}
  end

  @impl true
  def handle_info(%Broadcast{topic: topic, event: event, payload: payload}, socket) do
    # TODO: can we get rid of this now?
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

  @spec broadcast_new_message(Message.t(), any()) :: Message.t()
  defp broadcast_new_message(%Message{private: true} = message, socket) do
    # For private messages, we only need to broadcast back to the admin channel,
    # the internal Slack channel, and webhooks. (We avoid broadcasting to the
    # customer channel or any public Slack channel or email.)
    broadcast(socket, "shout", Messages.Helpers.format(message))

    message
    |> Messages.Notification.notify(:slack)
    |> Messages.Notification.notify(:webhooks)
    |> Messages.Notification.notify(:mentions)
  end

  defp broadcast_new_message(message, socket) do
    broadcast(socket, "shout", Messages.Helpers.format(message))

    message
    |> Messages.Notification.broadcast_to_customer!()
    |> Messages.Notification.notify(:slack)
    |> Messages.Notification.notify(:slack_support_channel)
    |> Messages.Notification.notify(:slack_company_channel)
    |> Messages.Notification.notify(:mattermost)
    |> Messages.Notification.notify(:webhooks)
    |> Messages.Notification.notify(:mentions)
    |> Messages.Notification.notify(:conversation_reply_email)
    |> Messages.Notification.notify(:gmail)
    |> Messages.Notification.notify(:sms)
  end

  @spec authorized?(any(), binary()) :: boolean()
  defp authorized?(socket, account_id) do
    with %{current_user: current_user} <- socket.assigns,
         %{account_id: acct} <- current_user do
      acct == account_id
    else
      _ -> false
    end
  end
end
