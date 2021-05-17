defmodule ChatApi.Messages.Helpers do
  @moduledoc """
  Helpers for Messages context
  """

  alias ChatApi.Conversations
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message

  @spec get_conversation_topic(Message.t()) :: binary()
  def get_conversation_topic(%Message{conversation_id: conversation_id} = _message),
    do: "conversation:" <> conversation_id

  @spec get_admin_topic(Message.t()) :: binary()
  def get_admin_topic(%Message{account_id: account_id} = _message),
    do: "notification:" <> account_id

  @spec format(Message.t()) :: map()
  def format(%Message{} = message),
    do: ChatApiWeb.MessageView.render("expanded.json", message: message)

  @spec get_message_type(Message.t()) :: atom()
  def get_message_type(%Message{type: "bot"}), do: :bot
  def get_message_type(%Message{customer_id: nil}), do: :agent
  def get_message_type(%Message{user_id: nil}), do: :customer
  def get_message_type(_message), do: :unknown

  @spec handle_post_creation_conversation_updates(Message.t(), map()) :: Message.t()
  def handle_post_creation_conversation_updates(%Message{} = message, updates \\ %{}) do
    message
    |> build_conversation_updates(updates)
    |> update_message_conversation(message)
    |> Conversations.Notification.broadcast_conversation_update_to_admin!()
    |> Conversations.Notification.notify(:webhooks, event: "conversation:updated")
    |> Conversations.Notification.notify(:slack)

    message
  end

  @spec handle_post_creation_hooks(Message.t(), map()) :: Message.t()
  def handle_post_creation_hooks(%Message{} = message, updates \\ %{}) do
    message
    |> handle_post_creation_conversation_updates(updates)
    |> handle_linking_github_issues()

    message
  end

  @spec handle_linking_github_issues(Message.t()) :: Message.t()
  def handle_linking_github_issues(%Message{type: "bot"} = message), do: message

  def handle_linking_github_issues(
        %Message{
          body: body,
          conversation_id: conversation_id,
          account_id: account_id
        } = message
      ) do
    with [_ | _] = links <- ChatApi.Github.Helpers.extract_github_issue_links(body),
         %Conversation{customer: customer} = conversation <-
           Conversations.get_conversation_with(conversation_id, [:customer, :messages]),
         user_id <- get_conversation_agent_id(conversation) do
      Enum.each(links, fn url ->
        {:ok, issue} =
          ChatApi.Issues.find_or_create_by_github_url(url, %{
            account_id: account_id,
            creator_id: user_id
          })

        {:ok, _} = ChatApi.Customers.link_issue(customer, issue.id)
        # TODO: broadcast update to client
        # TODO: send bot message notifying admin that the issue has been linked to the customer/conversation
        # TODO: support linking issues to conversations (as well as customers)
        # TODO: when issue is closed, notify linked conversations with (private?) bot message
      end)
    end

    message
  end

  @spec build_conversation_updates(Message.t(), map()) :: map()
  def build_conversation_updates(%Message{} = message, updates \\ %{}) do
    updates
    |> build_first_reply_updates(message)
    |> build_message_type_updates(message)
  end

  @spec is_first_agent_reply?(Message.t()) :: boolean()
  def is_first_agent_reply?(%Message{conversation_id: conversation_id, user_id: assignee_id}) do
    !is_nil(assignee_id) && Conversations.count_agent_replies(conversation_id) == 1
  end

  @spec build_first_reply_updates(map(), Message.t()) :: map()
  defp build_first_reply_updates(
         updates,
         %Message{user_id: assignee_id, inserted_at: first_replied_at} = message
       ) do
    if is_first_agent_reply?(message) do
      Map.merge(updates, %{assignee_id: assignee_id, first_replied_at: first_replied_at})
    else
      updates
    end
  end

  @spec build_message_type_updates(map(), Message.t()) :: map()
  defp build_message_type_updates(updates, %Message{} = message) do
    case get_message_type(message) do
      # If agent responded, conversation should be marked as "read"
      :agent -> Map.merge(updates, %{read: true})
      # If customer responded, make sure conversation is "open"
      :customer -> Map.merge(updates, %{read: false, status: "open"})
      # Bot messages should be considered unread by default
      :bot -> Map.merge(updates, %{read: false})
      _ -> updates
    end
  end

  @spec update_message_conversation(map(), Message.t()) :: Conversation.t()
  defp update_message_conversation(updates, %Message{conversation_id: conversation_id}) do
    # TODO: don't perform update if conversation state already matches updates?
    conversation = Conversations.get_conversation!(conversation_id)
    # TODO: DRY up this logic with other places we do conversation updates w/ broadcasting?
    {:ok, conversation} = Conversations.update_conversation(conversation, updates)

    conversation
  end

  defp get_conversation_agent_id(%Conversation{account_id: account_id} = conversation) do
    agent_id =
      case conversation do
        %Conversation{assignee_id: assignee_id} when not is_nil(assignee_id) ->
          assignee_id

        %Conversation{messages: [_ | _] = messages} ->
          messages |> Enum.map(& &1.user_id) |> Enum.find(&(!is_nil(&1)))

        _ ->
          nil
      end

    case agent_id do
      nil -> account_id |> ChatApi.Accounts.get_primary_user() |> Map.get(:id)
      id -> id
    end
  end
end
