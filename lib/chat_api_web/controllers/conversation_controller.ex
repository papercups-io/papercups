defmodule ChatApiWeb.ConversationController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.Conversations
  alias ChatApi.Conversations.Conversation

  action_fallback(ChatApiWeb.FallbackController)

  def swagger_definitions do
    %{
      Conversation:
        swagger_schema do
          title("Conversation")
          description("A conversation in the app")

          properties do
            id(:string, "Conversation ID")
            status(:string, "Conversation status", required: true)
            priority(:string, "Priority status of the conversation")
            account_id(:string, "The ID of the associated account", required: true)
            customer_id(:string, "The ID of the customer", required: true)
            assignee_id(:string, "The ID of the assigned user")
            created_at(:string, "Created timestamp", format: :datetime)
            updated_at(:string, "Updated timestamp", format: :datetime)
          end

          example(%{
            status: "open",
            priority: "not_priority",
            account_id: "acct_1a2b3c",
            customer_id: "cus_1a2b3c"
          })
        end
    }
  end

  swagger_path :index do
    get("/api/conversations")
    summary("Query for conversations")
    description("Query for conversations. This operation supports filtering")

    parameter("Authorization", :header, :string, "OAuth2 access token", required: true)

    parameters do
      status(:query, :string, "Status of the conversation (e.g. open, closed)", example: "open")

      priority(:query, :string, "Conversation priority status (e.g. priority, not_priority)",
        example: "priority"
      )

      assignee_id(:query, :string, "The agent assigned to the conversation",
        example: "user_1a2b3c"
      )
    end

    response(200, "Success")
    response(401, "Not authenticated")
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      conversations = Conversations.list_conversations_by_account(account_id, params)

      render(conn, "index.json", conversations: conversations)
    end
  end

  @spec find_by_customer(Plug.Conn.t(), map) :: Plug.Conn.t()
  def find_by_customer(conn, %{"customer_id" => customer_id, "account_id" => account_id}) do
    conversations = Conversations.find_by_customer(customer_id, account_id)

    render(conn, "index.json", conversations: conversations)
  end

  swagger_path :create do
    post("/api/conversations")
    summary("Create a conversation")
    description("Create a new conversation")

    parameter(:conversation, :body, :object, "The conversation details")

    response(201, "Success")
    response(422, "Unprocessable entity")
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"conversation" => conversation_params}) do
    with {:ok, %Conversation{} = conversation} <-
           Conversations.create_conversation(conversation_params) do
      %{id: conversation_id, account_id: account_id} = conversation

      ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:created", %{
        "id" => conversation_id
      })

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.conversation_path(conn, :show, conversation))
      |> render("create.json", conversation: conversation)
    end
  end

  swagger_path :show do
    get("/api/conversations/{id}")
    summary("Retrieve a conversation")
    description("Retrieve an existing conversation")

    parameter("Authorization", :header, :string, "OAuth2 access token", required: true)
    parameter(:id, :path, :string, "Conversation ID", required: true)

    response(200, "Success")
    response(401, "Not authenticated")
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    conversation = Conversations.get_conversation!(id)
    render(conn, "show.json", conversation: conversation)
  end

  swagger_path :update do
    put("/api/conversations/{id}")
    summary("Update a conversation")
    description("Update an existing conversation")

    parameter("Authorization", :header, :string, "OAuth2 access token", required: true)
    parameter(:id, :path, :string, "Conversation ID", required: true)
    parameter(:conversation, :body, :object, "The conversation updates")

    response(200, "Success")
    response(401, "Not authenticated")
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "conversation" => conversation_params}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, %Conversation{} = conversation} <-
           Conversations.update_conversation(conversation, conversation_params) do
      render(conn, "update.json", conversation: conversation)
    end
  end

  @spec delete(Plug.Conn.t(), map) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, %Conversation{}} <- Conversations.delete_conversation(conversation) do
      send_resp(conn, :no_content, "")
    end
  end
end
