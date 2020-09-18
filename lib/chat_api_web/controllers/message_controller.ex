defmodule ChatApiWeb.MessageController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.Messages
  alias ChatApi.Messages.Message

  action_fallback(ChatApiWeb.FallbackController)

  def swagger_definitions do
    %{
      Message:
        swagger_schema do
          title("Message")
          description("A message in the app")

          properties do
            id(:string, "Message ID")
            body(:string, "Message body", required: true)
            account_id(:string, "The ID of the associated account", required: true)
            conversation_id(:string, "The ID of the associated conversation", required: true)
            customer_id(:string, "The ID of the customer")
            user_id(:string, "The ID of the user/agent")
            created_at(:string, "Created timestamp", format: :datetime)
            updated_at(:string, "Updated timestamp", format: :datetime)
          end

          example(%{
            body: "Hello world!",
            customer_id: "cus_1a2b3c",
            conversation_id: "conv_1a2b3c",
            account_id: "acct_1a2b3c",
            user_id: "user_1a2b3c"
          })
        end
    }
  end

  swagger_path :index do
    get("/api/messages")
    summary("Query for messages")
    description("Query for messages.")

    parameter("Authorization", :header, :string, "OAuth2 access token", required: true)

    response(200, "Success")
    response(401, "Not authenticated")
  end

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      messages = Messages.list_messages(account_id)
      render(conn, "index.json", messages: messages)
    end
  end

  @spec count(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def count(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      count = Messages.count_messages_by_account(account_id)

      json(conn, %{data: %{count: count}})
    end
  end

  swagger_path :create do
    post("/api/messages")
    summary("Create a message")
    description("Create a new message")

    parameter("Authorization", :header, :string, "OAuth2 access token", required: true)
    parameter(:message, :body, :object, "The message details")

    response(201, "Success")
    response(422, "Unprocessable entity")
    response(401, "Not authenticated")
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"message" => message_params}) do
    with %{id: user_id, account_id: account_id} <- conn.assigns.current_user,
         {:ok, %Message{} = msg} <-
           message_params
           |> Map.merge(%{"user_id" => user_id, "account_id" => account_id})
           |> Messages.create_message(),
         message <-
           Messages.get_message!(msg.id) do
      broadcast_new_message(message)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.message_path(conn, :show, message))
      |> render("show.json", message: message)
    end
  end

  swagger_path :show do
    get("/api/messages/{id}")
    summary("Retrieve a message")
    description("Retrieve an existing message")

    parameter("Authorization", :header, :string, "OAuth2 access token", required: true)
    parameter(:id, :path, :string, "Message ID", required: true)

    response(200, "Success")
    response(401, "Not authenticated")
  end

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    message = Messages.get_message!(id)
    render(conn, "show.json", message: message)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "message" => message_params}) do
    message = Messages.get_message!(id)

    with {:ok, %Message{} = message} <- Messages.update_message(message, message_params) do
      render(conn, "show.json", message: message)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    message = Messages.get_message!(id)

    with {:ok, %Message{}} <- Messages.delete_message(message) do
      send_resp(conn, :no_content, "")
    end
  end

  defp broadcast_new_message(message) do
    message
    |> Messages.broadcast_to_conversation!()
    |> Messages.notify(:slack)
    |> Messages.notify(:webhooks)
  end
end
