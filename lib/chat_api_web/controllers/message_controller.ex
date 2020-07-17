defmodule ChatApiWeb.MessageController do
  use ChatApiWeb, :controller

  alias ChatApi.Chat
  alias ChatApi.Chat.Message

  action_fallback(ChatApiWeb.FallbackController)

  def index(conn, _params) do
    messages = Chat.list_messages()
    render(conn, "index.json", messages: messages)
  end

  def count(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      count = Chat.count_messages_by_account(account_id)

      json(conn, %{data: %{count: count}})
    end
  end

  def create(conn, %{"message" => message_params}) do
    with {:ok, %Message{} = message} <- Chat.create_message(message_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.message_path(conn, :show, message))
      |> render("show.json", message: message)
    end
  end

  def show(conn, %{"id" => id}) do
    message = Chat.get_message!(id)
    render(conn, "show.json", message: message)
  end

  def update(conn, %{"id" => id, "message" => message_params}) do
    message = Chat.get_message!(id)

    with {:ok, %Message{} = message} <- Chat.update_message(message, message_params) do
      render(conn, "show.json", message: message)
    end
  end

  def delete(conn, %{"id" => id}) do
    message = Chat.get_message!(id)

    with {:ok, %Message{}} <- Chat.delete_message(message) do
      send_resp(conn, :no_content, "")
    end
  end
end
