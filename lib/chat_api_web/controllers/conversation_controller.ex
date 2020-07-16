defmodule ChatApiWeb.ConversationController do
  use ChatApiWeb, :controller

  alias ChatApi.Conversations
  alias ChatApi.Conversations.Conversation

  action_fallback(ChatApiWeb.FallbackController)

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      conversations = Conversations.list_conversations_by_account(account_id, params)

      render(conn, "index.json", conversations: conversations)
    end
  end

  def find_by_customer(conn, %{"customer_id" => customer_id, "account_id" => account_id}) do
    conversations = Conversations.find_by_customer(customer_id, account_id)

    render(conn, "index.json", conversations: conversations)
  end

  def create(conn, %{"conversation" => conversation_params}) do
    with {:ok, %Conversation{} = conversation} <-
           Conversations.create_conversation(conversation_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.conversation_path(conn, :show, conversation))
      |> render("create.json", conversation: conversation)
    end
  end

  def show(conn, %{"id" => id}) do
    conversation = Conversations.get_conversation!(id)
    render(conn, "show.json", conversation: conversation)
  end

  def update(conn, %{"id" => id, "conversation" => conversation_params}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, %Conversation{} = conversation} <-
           Conversations.update_conversation(conversation, conversation_params) do
      render(conn, "update.json", conversation: conversation)
    end
  end

  def delete(conn, %{"id" => id}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, %Conversation{}} <- Conversations.delete_conversation(conversation) do
      send_resp(conn, :no_content, "")
    end
  end
end
