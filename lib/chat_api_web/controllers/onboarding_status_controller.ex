defmodule ChatApiWeb.OnboardingStatusController do
  use ChatApiWeb, :controller

  alias ChatApi.{
    Accounts,
    BrowserSessions,
    Github,
    Google,
    Mattermost,
    SlackAuthorizations,
    Twilio,
    Users
  }

  alias Users.{UserProfile}

  action_fallback(ChatApiWeb.FallbackController)

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with current_user <- Pow.Plug.current_user(conn),
         %{account_id: account_id} <- current_user do
      account = Accounts.get_account!(account_id)

      json(conn, %{
        has_configured_profile: has_configured_profile?(current_user.id),
        has_configured_storytime: has_configured_storytime?(account_id),
        has_integrations: has_integrations?(account_id),
        has_invited_teammates: has_invited_teammates?(account_id),
        has_upgraded_subscription: has_upgraded_subscription?(account),
        is_chat_widget_installed: is_chat_widget_installed?(account)
      })
    end
  end

  @spec has_configured_profile?(number()) :: boolean()
  defp has_configured_profile?(user_id) do
    case Users.get_user_profile(user_id) do
      nil -> false
      %UserProfile{display_name: nil, full_name: nil, profile_photo_url: nil} -> false
      %UserProfile{} -> true
    end
  end

  # @spec has_integrations?(binary()) :: boolean()
  defp has_integrations?(account_id) do
    tasks_with_results =
      Task.yield_many([
        Task.async(fn -> Github.get_authorization_by_account(account_id) end),
        Task.async(fn -> Google.get_authorization_by_account(account_id) end),
        Task.async(fn -> Mattermost.get_authorization_by_account(account_id) end),
        Task.async(fn ->
          SlackAuthorizations.find_slack_authorization(%{account_id: account_id})
        end),
        Task.async(fn -> Twilio.get_authorization_by_account(account_id) end)
      ])

    results =
      Enum.map(tasks_with_results, fn {task, res} ->
        # Shut down the tasks that did not reply nor exit
        res || Task.shutdown(task, :brutal_kill)
      end)

    Enum.any?(results, fn result ->
      case result do
        {:ok, value} -> value != nil
        _ -> false
      end
    end)
  end

  defp is_chat_widget_installed?(account) do
    host = account.widget_settings && account.widget_settings.host
    host != nil && !String.contains?(host, ["papercups", "localhost"])
  end

  defp has_invited_teammates?(account_id) do
    Accounts.count_active_users(account_id) > 1
  end

  defp has_upgraded_subscription?(account) do
    account.subscription_plan != "starter"
  end

  defp has_configured_storytime?(account_id) do
    BrowserSessions.has_browser_sessions?(account_id)
  end
end
