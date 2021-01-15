defmodule ChatApiWeb.ConversationController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.Conversations
  alias ChatApi.Conversations.{Conversation, Helpers}
  alias ChatApi.Messages

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

  # TODO: figure out a better way to handle this
  @spec find_by_customer(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def find_by_customer(conn, %{"customer_id" => customer_id, "account_id" => account_id}) do
    conversations = Conversations.find_by_customer(customer_id, account_id)

    render(conn, "index.json", conversations: conversations)
  end

  @spec share(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def share(conn, %{"conversation_id" => conversation_id}) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %{customer_id: customer_id} <- Conversations.get_conversation!(conversation_id) do
      token = Phoenix.Token.sign(ChatApiWeb.Endpoint, conversation_id, {account_id, customer_id})

      json(conn, %{data: %{ok: true, token: token}})
    end
  end

  @spec shared(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def shared(conn, %{"conversation_id" => conversation_id, "token" => token}) do
    # We set a max_age of 86400, which is the equivalent of 24 hours (after which the token expires)
    case Phoenix.Token.verify(ChatApiWeb.Endpoint, conversation_id, token, max_age: 86400) do
      {:ok, {account_id, customer_id}} ->
        conversation =
          Conversations.get_shared_conversation!(conversation_id, account_id, customer_id)

        render(conn, "show.json", conversation: conversation)

      {:error, :expired} ->
        conn
        |> put_status(403)
        |> json(%{error: %{status: 403, message: "This link has expired"}})

      _errors ->
        conn
        |> put_status(403)
        |> json(%{error: %{status: 403, message: "Access denied"}})
    end
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
  def create(%{assigns: %{current_user: %{account_id: account_id}}} = conn, %{
        "conversation" => params
      }) do
    with {:ok, %Conversation{} = conversation} <-
           params
           |> Map.merge(%{"account_id" => account_id})
           |> Conversations.create_conversation(),
         :ok <- maybe_create_message(conn, conversation, params) do
      broadcast_conversation_to_admin!(conversation)
      broadcast_conversation_to_customer!(conversation)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.conversation_path(conn, :show, conversation))
      |> render("create.json", conversation: conversation)
    end
  end

  def create(conn, %{"conversation" => conversation_params}) do
    # TODO: add support for creating a conversation with an initial message here as well?
    with {:ok, %Conversation{} = conversation} <-
           Conversations.create_conversation(conversation_params) do
      broadcast_conversation_to_admin!(conversation)
      broadcast_conversation_to_customer!(conversation)

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

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
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

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"id" => id, "conversation" => conversation_params}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, %Conversation{} = conversation} <-
           Conversations.update_conversation(conversation, conversation_params) do
      Task.start(fn ->
        Helpers.send_conversation_state_update(conversation, conversation_params)
      end)

      render(conn, "update.json", conversation: conversation)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    conversation = Conversations.get_conversation!(id)

    # Sending a message to Slack first before deleting since there's no conversation to
    # send to after it's deleted.
    with {:ok, _} <-
           Helpers.send_conversation_state_update(conversation, %{"state" => "deleted"}),
         {:ok, %Conversation{}} <- Conversations.delete_conversation(conversation) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec add_tag(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add_tag(conn, %{"conversation_id" => id, "tag_id" => tag_id}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, _result} <- Conversations.add_tag(conversation, tag_id) do
      json(conn, %{data: %{ok: true}})
    end
  end

  @spec remove_tag(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def remove_tag(conn, %{"conversation_id" => id, "tag_id" => tag_id}) do
    conversation = Conversations.get_conversation!(id)

    with {:ok, _result} <- Conversations.remove_tag(conversation, tag_id) do
      json(conn, %{data: %{ok: true}})
    end
  end

  @spec maybe_create_message(Plug.Conn.t(), Conversation.t(), map()) :: any()
  defp maybe_create_message(
         conn,
         conversation,
         %{"message" => %{"body" => _body} = message_params}
       ) do
    with %{id: user_id, account_id: account_id} <- conn.assigns.current_user,
         {:ok, %Messages.Message{} = msg} <-
           message_params
           |> Map.merge(%{
             "user_id" => user_id,
             "account_id" => account_id,
             "conversation_id" => conversation.id
           })
           |> Messages.create_message() do
      Messages.get_message!(msg.id)
      |> Messages.Notification.broadcast_to_conversation!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:webhooks)

      :ok
    end
  end

  defp maybe_create_message(_conn, _conversation, _), do: :ok

  defp broadcast_conversation_to_admin!(
         %Conversation{id: conversation_id, account_id: account_id} = conversation
       ) do
    ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:created", %{
      "id" => conversation_id
    })

    conversation
  end

  defp broadcast_conversation_to_customer!(
         %Conversation{id: conversation_id, customer_id: customer_id} = conversation
       ) do
    ChatApiWeb.Endpoint.broadcast!(
      "conversation:lobby:" <> customer_id,
      "conversation:created",
      %{
        "id" => conversation_id
      }
    )

    conversation
  end
end
