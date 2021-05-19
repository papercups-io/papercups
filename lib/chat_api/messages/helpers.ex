defmodule ChatApi.Messages.Helpers do
  @moduledoc """
  Helpers for Messages context
  """

  alias ChatApi.{Conversations, Customers, Github, Issues, Messages}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Github.GithubAuthorization
  alias ChatApi.Issues.Issue
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
  def handle_linking_github_issues(%Message{} = message) do
    # TODO: use oban instead?
    Task.start(fn -> link_github_issues_to_customer(message) end)

    message
  end

  # TODO: maybe this belongs in another module?
  @spec link_github_issues_to_customer(Message.t()) :: Message.t()
  def link_github_issues_to_customer(%Message{type: "bot"} = message), do: message

  def link_github_issues_to_customer(
        %Message{
          body: body,
          conversation_id: conversation_id,
          account_id: account_id
        } = message
      ) do
    with [_ | _] = links <- Github.Helpers.extract_github_issue_links(body),
         %GithubAuthorization{} = auth <- Github.get_authorization_by_account(account_id),
         %Conversation{customer: customer} = conversation <-
           Conversations.get_conversation_with(conversation_id, [:customer, :messages]),
         user_id <- get_conversation_agent_id(conversation) do
      new_github_links =
        links
        |> Enum.filter(fn url -> Github.Helpers.subscribed_to_repo?(url, auth) end)
        |> Enum.map(fn url ->
          {:ok, issue} =
            Issues.find_or_create_by_github_url(url, %{
              account_id: account_id,
              creator_id: user_id
            })

          case Customers.get_issue(customer, issue.id) do
            nil ->
              {:ok, _} = Customers.link_issue(customer, issue.id)
              notify_customer_issues_channel(customer.id, issue)

              url

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      automated_message =
        case new_github_links do
          [new_link] ->
            "Looks like there is a GitHub link in that message: " <>
              "\n - " <>
              new_link <>
              "\n\n" <>
              "We've automatically linked that issue to this customer so you can notify them once the issue is resolved. " <>
              "(Click [here](/integrations) to configure the GitHub integration for your account)"

          [_ | _] = new_links ->
            list = new_links |> Enum.map(fn link -> "\n - " <> link end) |> Enum.join("")

            "Looks like there are some GitHub links in that message:" <>
              list <>
              "\n\n" <>
              "We've automatically linked those issues to this customer so you can notify them once those issues are resolved. " <>
              "(Click [here](/integrations) to configure the GitHub integration for your account)"

          _ ->
            nil
        end

      case automated_message do
        body when is_binary(body) ->
          # Wait 2s before sending automated message
          Process.sleep(2000)

          %{
            body: body,
            type: "bot",
            private: true,
            conversation_id: conversation_id,
            account_id: account_id,
            user_id: user_id,
            sent_at: DateTime.utc_now()
          }
          |> Messages.create_and_fetch!()
          |> Messages.Notification.broadcast_to_admin!()
          |> Messages.Notification.notify(:slack)
          |> Messages.Notification.notify(:mattermost)
          |> Messages.Notification.notify(:webhooks)

        _ ->
          nil
      end

      message
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

  defp notify_customer_issues_channel(customer_id, %Issue{} = issue) do
    ChatApiWeb.Endpoint.broadcast!(
      "issue:lobby:" <> customer_id,
      "issue:created",
      ChatApiWeb.IssueView.render("issue.json", issue: issue)
    )
  end
end
