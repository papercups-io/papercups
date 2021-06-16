defmodule ChatApiWeb.SetupStatusController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, BrowserSessions, Github, Google, Mattermost, SlackAuthorizations, Twilio, Users}

  action_fallback(ChatApiWeb.FallbackController)

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    with current_user <- Pow.Plug.current_user(conn),
         %{account_id: account_id} <- current_user do
      account = Accounts.get_account!(account_id)

      json(conn, %{
        configured_profile: configured_profile?(current_user.id),
        configured_storytime: configured_storytime?(account_id),
        has_integrations: has_integrations?(account_id),
        installed_chat_widget: installed_chat_widget?(account),
        invited_teammates: invited_teammates?(account_id),
        upgraded_subscription: upgraded_subscription?(account)
      })
    end
  end

  @spec configured_profile?(number()) :: boolean()
  def configured_profile?(user_id) do
    profile = Users.get_user_profile(user_id)
    profile.display_name != nil || profile.full_name != nil || profile.profile_photo_url != nil
  end

  @spec has_integrations?(binary()) :: boolean()
  def has_integrations?(account_id) do
    github_authorization = Github.get_authorization_by_account(account_id)
    google_authorization = Google.get_authorization_by_account(account_id)
    mattermost_authorization = Mattermost.get_authorization_by_account(account_id)
    slack_authorization = SlackAuthorizations.find_slack_authorization(%{account_id: account_id})
    twilio_authorization = Twilio.get_authorization_by_account(account_id)

    Enum.any?([
      github_authorization,
      google_authorization,
      mattermost_authorization,
      slack_authorization,
      twilio_authorization
    ])
  end

  def installed_chat_widget?(account) do
    host = account.widget_settings.host
    host != nil && !String.contains?(host, ["papercups", "localhost"])
  end

  def invited_teammates?(account_id) do
    Accounts.count_active_users(account_id) > 1
  end

  def upgraded_subscription?(account) do
    account.subscription_plan != "starter"
  end

  def configured_storytime?(account_id) do
    BrowserSessions.has_browser_sessions?(account_id)
  end
end
