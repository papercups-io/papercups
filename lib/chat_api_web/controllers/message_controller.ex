defmodule ChatApiWeb.MessageController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.Messages
  alias ChatApi.Messages.Message

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete])

  defp authorize(conn, _) do
    id = conn.path_params["id"]

    with %{id: _user_id, account_id: account_id} <- conn.assigns.current_user,
         message = %{account_id: ^account_id} <- Messages.get_message!(id) do
      assign(conn, :current_message, message)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

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
  def index(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      messages = Messages.list_messages(account_id, params)
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
    with {:ok, params} <- sanitize_new_message_params(conn, message_params),
         {:ok, %Message{} = msg} <- Messages.create_message(params),
         message <- Messages.get_message!(msg.id) do
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
  def show(conn, _params) do
    message = conn.assigns.current_message
    render(conn, "show.json", message: message)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"message" => message_params}) do
    message = conn.assigns.current_message

    with %{account_id: account_id} <- conn.assigns.current_user,
         sanitized_updates <- Map.merge(message_params, %{"account_id" => account_id}),
         {:ok, %Message{} = message} <- Messages.update_message(message, sanitized_updates) do
      render(conn, "show.json", message: message)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    message = conn.assigns.current_message

    with {:ok, %Message{}} <- Messages.delete_message(message) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec sanitize_new_message_params(Plug.Conn.t(), map()) ::
          {:ok, map()} | {:error, atom(), binary()}
  defp sanitize_new_message_params(
         _conn,
         %{"customer_id" => customer_id, "user_id" => user_id}
       )
       when is_binary(customer_id) and not is_nil(user_id) do
    {:error, :unprocessable_entity,
     "A message should not have both a `user_id` and `customer_id`"}
  end

  defp sanitize_new_message_params(conn, %{"customer_id" => customer_id} = params)
       when is_binary(customer_id) do
    account_id = conn.assigns.current_user.account_id
    customer = ChatApi.Customers.get_customer!(customer_id, [])

    case customer do
      %{account_id: ^account_id} ->
        {:ok, Map.merge(params, %{"account_id" => account_id})}

      _ ->
        {:error, :forbidden, "Forbidden: invalid `customer_id`"}
    end
  end

  defp sanitize_new_message_params(conn, params) do
    case conn.assigns.current_user do
      %{id: user_id, account_id: account_id} ->
        {:ok, Map.merge(params, %{"user_id" => user_id, "account_id" => account_id})}

      _ ->
        {:error, :unauthorized, "Access denied"}
    end
  end

  defp broadcast_new_message(message) do
    message
    |> Messages.Notification.broadcast_to_customer!()
    |> Messages.Notification.broadcast_to_admin!()
    |> Messages.Notification.notify(:slack)
    |> Messages.Notification.notify(:slack_support_channel)
    |> Messages.Notification.notify(:slack_company_channel)
    |> Messages.Notification.notify(:mattermost)
    |> Messages.Notification.notify(:webhooks)
    |> Messages.Notification.notify(:conversation_reply_email)
    |> Messages.Notification.notify(:gmail)
    |> Messages.Notification.notify(:sms)
  end
end
