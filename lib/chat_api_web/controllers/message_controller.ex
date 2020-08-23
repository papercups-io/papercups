defmodule ChatApiWeb.MessageController do
  use ChatApiWeb, :controller

  alias ChatApi.{EventSubscriptions, Messages}
  alias ChatApi.Messages.Message

  action_fallback(ChatApiWeb.FallbackController)

  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      messages = Messages.list_messages(account_id)
      render(conn, "index.json", messages: messages)
    end
  end

  def count(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      count = Messages.count_messages_by_account(account_id)

      json(conn, %{data: %{count: count}})
    end
  end

  def create(conn, %{"message" => message_params}) do
    with {:ok, %Message{} = msg} <- Messages.create_message(message_params),
         message <- Messages.get_message!(msg.id) do
      broadcast_new_message(message)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.message_path(conn, :show, message))
      |> render("show.json", message: message)
    end
  end

  def show(conn, %{"id" => id}) do
    message = Messages.get_message!(id)
    render(conn, "show.json", message: message)
  end

  def update(conn, %{"id" => id, "message" => message_params}) do
    message = Messages.get_message!(id)

    with {:ok, %Message{} = message} <- Messages.update_message(message, message_params) do
      render(conn, "show.json", message: message)
    end
  end

  def delete(conn, %{"id" => id}) do
    message = Messages.get_message!(id)

    with {:ok, %Message{}} <- Messages.delete_message(message) do
      send_resp(conn, :no_content, "")
    end
  end

  defp broadcast_new_message(message) do
    json = ChatApiWeb.MessageView.render("expanded.json", message: message)
    %{conversation_id: conversation_id, account_id: account_id} = message
    topic = "conversation:" <> conversation_id

    ChatApiWeb.Endpoint.broadcast!(topic, "shout", json)

    # Handling async for now
    Task.start(fn ->
      send_message_alerts(message)
    end)

    Task.start(fn ->
      send_webhook_notifications(account_id, json)
    end)
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
end
