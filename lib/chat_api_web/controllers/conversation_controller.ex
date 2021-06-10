defmodule ChatApiWeb.ConversationController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.{Conversations, Messages}
  alias ChatApi.Conversations.{Conversation, Helpers}

  action_fallback(ChatApiWeb.FallbackController)

  plug(:authorize when action in [:show, :update, :delete, :archive])

  defp authorize(conn, _) do
    id = conn.path_params["id"] || conn.params["conversation_id"]

    with %{account_id: account_id} <- conn.assigns.current_user,
         conversation = %{account_id: ^account_id} <- Conversations.get_conversation!(id) do
      assign(conn, :current_conversation, conversation)
    else
      _ -> ChatApiWeb.FallbackController.call(conn, {:error, :not_found}) |> halt()
    end
  end

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
    with %{account_id: account_id} <- conn.assigns.current_user,
         pagination_options <- format_pagination_options(params),
         %{entries: conversations, metadata: pagination} <-
           Conversations.list_conversations_by_account_paginated(
             account_id,
             params,
             pagination_options
           ) do
      render(conn, "index.json", conversations: conversations, pagination: pagination)
    end
  end

  # TODO: figure out a better way to handle this
  @spec find_by_customer(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def find_by_customer(conn, %{"customer_id" => customer_id, "account_id" => account_id}) do
    conversations = Conversations.find_by_customer(customer_id, account_id)

    render(conn, "index.json", conversations: conversations)
  end

  @spec previous(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def previous(conn, %{"conversation_id" => conversation_id}) do
    with %Conversation{} = conversation <- Conversations.get_conversation(conversation_id) do
      # TODO: should we just return the conversation ID?
      previous = Conversations.get_previous_conversation(conversation)

      render(conn, "show.json", conversation: previous)
    end
  end

  @spec related(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def related(conn, %{"conversation_id" => conversation_id} = params) do
    with %Conversation{} = conversation <-
           Conversations.get_conversation(conversation_id) do
      limit = Map.get(params, "limit", 3)
      results = Conversations.list_other_recent_conversations(conversation, limit)

      render(conn, "index.json", conversations: results)
    end
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
      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> Conversations.Notification.broadcast_new_conversation_to_customer!()
      |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

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
      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> Conversations.Notification.broadcast_new_conversation_to_customer!()
      |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

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
  def show(conn, _params) do
    render(conn, "show.json", conversation: conn.assigns.current_conversation)
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
  def update(conn, %{"conversation" => conversation_params}) do
    conversation = conn.assigns.current_conversation

    with {:ok, conversation} <-
           Conversations.update_conversation(conversation, conversation_params) do
      # Broadcast updates asynchronously if these channels have been configured
      conversation
      |> Conversations.Notification.notify(:slack)
      |> Conversations.Notification.notify(:webhooks, event: "conversation:updated")

      render(conn, "update.json", conversation: conversation)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conversation = conn.assigns.current_conversation

    # Sending a message to Slack first before deleting since there's no conversation to
    # send to after it's deleted.
    with {:ok, _} <-
           Helpers.send_conversation_state_update(conversation, %{"state" => "deleted"}),
         {:ok, %Conversation{}} <- Conversations.delete_conversation(conversation) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec archive(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def archive(conn, _params) do
    conversation = conn.assigns.current_conversation

    with {:ok, %Conversation{} = conversation} <- Conversations.archive_conversation(conversation) do
      render(conn, "update.json", conversation: conversation)
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
         %Conversation{source: "email"} = conversation,
         %{"message" => %{"body" => body} = _message_params}
       ) do
    with %{id: user_id} <- conn.assigns.current_user do
      case ChatApi.Google.InitializeGmailThread.send(body, conversation, user_id) do
        %Messages.Message{} -> :ok
        {:error, message} -> {:error, :unprocessable_entity, message}
      end
    end
  end

  defp maybe_create_message(
         conn,
         %Conversation{id: conversation_id},
         %{"message" => %{"body" => _body} = message_params}
       ) do
    with %{id: user_id, account_id: account_id} <- conn.assigns.current_user,
         {:ok, %Messages.Message{} = msg} <-
           message_params
           |> Map.merge(%{
             "user_id" => user_id,
             "account_id" => account_id,
             "conversation_id" => conversation_id
           })
           |> Messages.create_message() do
      Messages.get_message!(msg.id)
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:mattermost)
      |> Messages.Notification.notify(:webhooks)

      :ok
    end
  end

  defp maybe_create_message(_conn, _conversation, _), do: :ok

  defp format_pagination_options(params) do
    Enum.reduce(
      params,
      [],
      fn
        {"limit", value}, acc ->
          case Integer.parse(value) do
            {limit, ""} -> acc ++ [limit: limit]
            _ -> acc
          end

        {"after", value}, acc ->
          acc ++ [after: value]

        _, acc ->
          acc
      end
    )
  end
end
