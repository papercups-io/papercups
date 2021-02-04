defmodule Mix.Tasks.SetMissingSlackUserIds do
  use Mix.Task

  require Logger

  @shortdoc "Sets Slack user IDs for users with missing Slack ID based on email"

  @moduledoc """
  This task handles setting missing Slack user IDs for users on accounts with a
  Slack integration. It currently does this by matching on the `email` field.

  Example:
  ```
  $ mix set_missing_slack_user_ids
  ```

  On Heroku:
  ```
  $ heroku run "mix set_missing_slack_user_ids"
  ```

  """

  def run(_args) do
    Application.ensure_all_started(:chat_api)

    # The way this works:
    #   1. We fetch all Slack authorizations and group them by account
    #   2. We look for an authorization with the correct scopes for retrieving user info
    #   3. If a valid authorization is found, we use this to fetch the Slack users for the account
    #   4. Then, we compare the email field on the Slack user objects with the internal Papercups users' emails
    #   5. If we find a match, we update the user's `slack_user_id` field on their profile
    #
    ChatApi.SlackAuthorizations.list_slack_authorizations()
    |> Enum.group_by(& &1.account_id)
    |> Stream.map(fn {account_id, authorizations} ->
      auth =
        Enum.find(authorizations, fn auth ->
          String.contains?(auth.scope, "users:read") &&
            String.contains?(auth.scope, "users:read.email")
        end)

      {account_id, auth}
    end)
    |> Stream.reject(fn {_, auth} -> is_nil(auth) end)
    |> Enum.map(fn {account_id, auth} ->
      slack_users = retrieve_slack_users(auth.access_token)

      account_id
      |> list_users_with_unset_slack_id()
      |> Enum.map(fn user ->
        matching_slack_user = find_matching_slack_user(user, slack_users)

        {user, matching_slack_user}
      end)
      |> Enum.each(fn {user, matching_slack_user} ->
        case matching_slack_user do
          %{"id" => slack_user_id} ->
            Logger.debug(
              "Found matching Slack user #{inspect(slack_user_id)} for user #{inspect(user.email)}"
            )

            ChatApi.Users.update_user_profile(user.id, %{slack_user_id: slack_user_id})

          _ ->
            nil
        end
      end)
    end)
  end

  defp find_matching_slack_user(user, slack_users) do
    Enum.find(slack_users, fn slack_user ->
      case slack_user do
        %{"profile" => %{"email" => email}} when not is_nil(email) -> email == user.email
        _ -> false
      end
    end)
  end

  defp list_users_with_unset_slack_id(account_id) do
    account_id
    |> ChatApi.Users.list_users_by_account()
    |> Enum.reject(fn user ->
      case user do
        %{profile: %{slack_user_id: slack_user_id}} when not is_nil(slack_user_id) ->
          true

        _ ->
          false
      end
    end)
  end

  defp retrieve_slack_users(access_token) do
    with {:ok, response} <- ChatApi.Slack.Client.list_users(access_token),
         {:ok, users} <- ChatApi.Slack.Extractor.extract_valid_slack_users(response) do
      users
    else
      error ->
        Logger.error("Error retrieving Slack users: #{inspect(error)}")

        []
    end
  end
end
