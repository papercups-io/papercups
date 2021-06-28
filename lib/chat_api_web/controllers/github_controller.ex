defmodule ChatApiWeb.GithubController do
  use ChatApiWeb, :controller

  alias ChatApi.{Conversations, Github, Issues, Messages}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Github.GithubAuthorization
  alias ChatApi.Issues.Issue

  require Logger

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code}) do
    Logger.debug("Code from Github oauth: #{inspect(code)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         {:ok,
          %{body: %{"access_token" => access_token, "scope" => scope, "token_type" => token_type}}} <-
           Github.Client.get_access_token(code),
         {:ok, result} <-
           Github.create_or_update_authorization(%{
             account_id: account_id,
             user_id: user_id,
             access_token: access_token,
             scope: scope,
             token_type: token_type
           }) do
      json(conn, %{data: %{ok: true, id: result.id}})
    end
  end

  def oauth(conn, %{"setup_action" => "install", "installation_id" => installation_id}) do
    # TODO: generate the access token/refresh token using the `installation_id` plus the generated JWT
    Logger.debug("Setting up authorization for Github installation #{inspect(installation_id)}")

    with %{account_id: account_id, id: user_id} <- conn.assigns.current_user,
         {:ok, %{body: %{"token" => access_token, "expires_at" => expires_at} = metadata}} <-
           Github.Client.generate_installation_access_token(installation_id),
         {:ok, result} <-
           Github.create_or_update_authorization(%{
             account_id: account_id,
             user_id: user_id,
             access_token: access_token,
             access_token_expires_at: expires_at,
             github_installation_id: installation_id,
             metadata: metadata
           }) do
      json(conn, %{data: %{ok: true, id: result.id}})
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, _payload) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Github.get_authorization_by_account()

    case authorization do
      nil ->
        json(conn, %{data: nil})

      auth ->
        json(conn, %{
          data: %{
            id: auth.id,
            created_at: auth.inserted_at,
            token_type: auth.token_type,
            scope: auth.scope
          }
        })
    end
  end

  @spec list_repos(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_repos(conn, _payload) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %GithubAuthorization{} = auth <- Github.get_authorization_by_account(account_id),
         {:ok, %{body: %{"repositories" => repos}}} <- Github.Client.list_installation_repos(auth) do
      json(conn, %{data: repos})
    else
      error ->
        Logger.error("Could not retrieve GitHub repos: #{inspect(error)}")

        json(conn, %{data: []})
    end
  end

  @spec list_issues(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_issues(conn, %{"url" => url}) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Github.get_authorization_by_account()

    with {:ok, %{owner: owner, repo: repo, id: issue_id}} <-
           Github.Helpers.parse_github_issue_url(url),
         {:ok, %{body: %{"title" => _title, "body" => _body} = result}} <-
           Github.Client.retrieve_issue(authorization, owner, repo, issue_id) do
      json(conn, %{data: [result]})
    else
      {:error, :invalid_github_issue_url} ->
        {:error, :unprocessable_entity, "Invalid GitHub issue URL"}

      error ->
        Logger.error("Error retrieving GitHub issue(s) for #{url}: #{inspect(error)}")

        json(conn, %{data: []})
    end
  end

  def list_issues(conn, %{"owner" => owner, "repo" => repo}) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Github.get_authorization_by_account()

    with {:ok, %{body: body}} <-
           Github.Client.list_issues(authorization, owner, repo) do
      json(conn, %{data: body})
    else
      error ->
        Logger.error("Error retrieving GitHub issues for #{owner}/#{repo}: #{inspect(error)}")

        json(conn, %{data: []})
    end
  end

  def create_issue(conn, %{"owner" => owner, "repo" => repo, "issue" => issue}) do
    authorization =
      conn
      |> Pow.Plug.current_user()
      |> Map.get(:account_id)
      |> Github.get_authorization_by_account()

    with {:ok, %{body: body}} <-
           Github.Client.create_issue(authorization, owner, repo, issue) do
      json(conn, %{data: body})
    else
      error ->
        Logger.error("Error retrieving GitHub issues for #{owner}/#{repo}: #{inspect(error)}")

        json(conn, %{data: []})
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %GithubAuthorization{} = auth <-
           Github.get_github_authorization!(id),
         {:ok, %GithubAuthorization{}} <- Github.delete_github_authorization(auth) do
      {:ok, _} =
        case auth.github_installation_id do
          nil -> {:ok, nil}
          installation_id -> Github.Client.delete_installation(installation_id)
        end

      send_resp(conn, :no_content, "")
    end
  end

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, payload) do
    conn
    |> get_req_header("x-github-event")
    |> List.first()
    |> handle_event(payload)

    # Just respond with a 200 no matter what for now
    send_resp(conn, 200, "")
  end

  defp notify_channel_subscriptions(customer_id, %Issue{} = issue) do
    ChatApiWeb.Endpoint.broadcast!(
      "issue:lobby:" <> customer_id,
      "issue:updated",
      ChatApiWeb.IssueView.render("issue.json", issue: issue)
    )
  end

  defp notify_linked_customers(
         %Issue{
           id: issue_id,
           account_id: account_id,
           creator_id: creator_id,
           github_issue_url: github_issue_url
         } = issue,
         action
       ) do
    issue_id
    |> Issues.list_customers_by_issue()
    |> Enum.each(fn customer ->
      notify_channel_subscriptions(customer.id, issue)

      case Conversations.find_latest_conversation(account_id, %{"customer_id" => customer.id}) do
        nil ->
          nil

        conversation ->
          user_id = creator_id || get_conversation_agent_id(conversation)

          emoji =
            case action do
              :closed -> ":white_check_mark:"
              :reopened -> ":mega:"
            end

          %{
            body:
              "#{emoji} A GitHub issue that this person is subscribed to has been #{
                to_string(action)
              }: " <>
                github_issue_url,
            type: "bot",
            private: true,
            conversation_id: conversation.id,
            account_id: account_id,
            user_id: user_id,
            sent_at: DateTime.utc_now()
          }
          |> Messages.create_and_fetch!()
          |> Messages.Notification.broadcast_to_admin!()
          |> Messages.Notification.notify(:slack)
          |> Messages.Notification.notify(:mattermost)
          |> Messages.Notification.notify(:webhooks)
          # Make sure conversation is re-opened if it is currently closed
          |> Messages.Helpers.handle_post_creation_hooks(%{status: "open"})
      end
    end)
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

  defp handle_event(
         "installation",
         %{"action" => "created", "installation" => installation} = payload
       ) do
    # TODO: handle new installation added (create new github_authorization record)
    Logger.debug(
      "Handling new Github installation event: #{inspect(payload)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(
         "installation",
         %{
           "action" => "deleted",
           "installation" => %{"id" => installation_id} = installation
         } = _payload
       ) do
    Logger.debug("Handling Github installation deleted event: #{inspect(installation)}")

    %{github_installation_id: Integer.to_string(installation_id)}
    |> Github.find_github_authorization()
    |> case do
      nil ->
        Logger.debug("No authorization found with installation ID #{inspect(installation_id)}")

      result ->
        Github.delete_github_authorization(result)
    end
  end

  defp handle_event(
         "issues",
         %{
           "action" => "closed",
           "installation" => installation,
           "issue" => issue
         } = _payload
       ) do
    Logger.debug(
      "Handling `closed` event for Github issue #{inspect(issue)} (installation #{
        inspect(installation)
      })"
    )

    with %{"id" => installation_id} <- installation,
         %{"html_url" => github_issue_url} <- issue,
         %GithubAuthorization{account_id: account_id} <-
           Github.find_github_authorization(%{
             github_installation_id: Integer.to_string(installation_id)
           }),
         %Issue{} = issue <-
           Issues.find_issue(%{account_id: account_id, github_issue_url: github_issue_url}) do
      {:ok, issue} = Issues.update_issue(issue, %{state: "done"})
      Task.start(fn -> notify_linked_customers(issue, :closed) end)

      Logger.debug("Successfully updated issue state: #{inspect(issue)}")
    end
  end

  defp handle_event(
         "issues",
         %{
           "action" => "reopened",
           "installation" => installation,
           "issue" => issue
         } = _payload
       ) do
    Logger.debug(
      "Handling `reopened` event for Github issue #{inspect(issue)} (installation #{
        inspect(installation)
      })"
    )

    with %{"id" => installation_id} <- installation,
         %{"html_url" => github_issue_url} <- issue,
         %GithubAuthorization{account_id: account_id} <-
           Github.find_github_authorization(%{
             github_installation_id: Integer.to_string(installation_id)
           }),
         %Issue{} = issue <-
           Issues.find_issue(%{account_id: account_id, github_issue_url: github_issue_url}) do
      {:ok, issue} = Issues.update_issue(issue, %{state: "unstarted"})
      Task.start(fn -> notify_linked_customers(issue, :reopened) end)

      Logger.debug("Successfully updated issue state: #{inspect(issue)}")
    end
  end

  defp handle_event(
         "issues",
         %{
           "action" => "opened",
           "installation" => installation,
           "issue" => issue
         } = _payload
       ) do
    Logger.debug(
      "Handling `opened` event for Github issue #{inspect(issue)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(
         "issue_comment",
         %{
           "action" => "created",
           "installation" => installation,
           "comment" => comment
         } = _event
       ) do
    Logger.debug(
      "Handling new Github comment event: #{inspect(comment)} (installation #{
        inspect(installation)
      })"
    )
  end

  defp handle_event(event, _payload) do
    Logger.debug("Unhandled Github webhook event: #{inspect(event)}")
  end
end
