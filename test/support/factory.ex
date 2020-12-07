defmodule ChatApi.Factory do
  use ExMachina.Ecto, repo: ChatApi.Repo

  # Factories
  def account_factory do
    %ChatApi.Accounts.Account{
      company_name: sequence("some company_name")
    }
  end

  def personal_api_key_factory do
    %ChatApi.ApiKeys.PersonalApiKey{
      account: build(:account),
      user: build(:user),
      value: sequence("some value"),
      label: "some label"
    }
  end

  def browser_replay_event_factory do
    %ChatApi.BrowserReplayEvents.BrowserReplayEvent{
      account: build(:account),
      browser_session: build(:browser_session),
      event: %{"foo" => "bar"}
    }
  end

  def browser_session_factory do
    %ChatApi.BrowserSessions.BrowserSession{
      finished_at: "2010-04-17T14:00:00Z",
      metadata: %{},
      started_at: "2010-04-17T14:00:00Z"
    }
  end

  def conversation_factory do
    %ChatApi.Conversations.Conversation{
      account: build(:account),
      customer: build(:customer),
      status: "open"
    }
  end

  def customer_factory do
    %ChatApi.Customers.Customer{
      first_seen: ~D[2020-01-01],
      last_seen: ~D[2020-01-01],
      email: sequence(:email, &"test-#{&1}@test.com"),
      account: build(:account),
      customer_tags: [],
      tags: []
    }
  end

  def event_subscription_factory do
    %ChatApi.EventSubscriptions.EventSubscription{
      account: build(:account),
      verified: false,
      webhook_url: "some webhook_url",
      scope: "some scope"
    }
  end

  def google_authorization_factory do
    %ChatApi.Google.GoogleAuthorization{
      client: "some client",
      refresh_token: "some long refresh token",
      account: build(:account),
      user: build(:user)
    }
  end

  def message_factory do
    %ChatApi.Messages.Message{
      account: build(:account),
      conversation: build(:conversation),
      customer: build(:customer),
      user: build(:user),
      body: "some message body"
    }
  end

  def slack_authorization_factory do
    %ChatApi.SlackAuthorizations.SlackAuthorization{
      access_token: "some access_token",
      app_id: sequence(:app_id, &"some app_id #{&1}"),
      authed_user_id: sequence(:authed_user_id, &"some authed_user_id #{&1}"),
      bot_user_id: sequence(:bot_user_id, &"some bot_user_id #{&1}"),
      channel: "some channel",
      channel_id: sequence(:channel_id, &"some channel_id #{&1}"),
      configuration_url: "some configuration_url",
      scope: "some scope",
      team_id: sequence(:team_id, &"some team_id #{&1}"),
      team_name: sequence(:team_name, &"some team_name #{&1}"),
      token_type: "some token_type",
      webhook_url: "some webhook_url",
      account: build(:account)
    }
  end

  def slack_conversation_thread_factory do
    %ChatApi.SlackConversationThreads.SlackConversationThread{
      account: build(:account),
      conversation: build(:conversation),
      slack_thread_ts: sequence("1234.56789"),
      slack_channel: "bots"
    }
  end

  def tag_factory do
    %ChatApi.Tags.Tag{
      account: build(:account),
      name: sequence("some name")
    }
  end

  def user_invitation_factory do
    %ChatApi.UserInvitations.UserInvitation{
      account: build(:account),
      expires_at: DateTime.add(DateTime.utc_now(), :timer.hours(168), :millisecond)
    }
  end

  @spec user_factory :: ChatApi.Users.User.t()
  def user_factory do
    %ChatApi.Users.User{
      email: sequence(:email, &"company_name-#{&1}@example.com"),
      account: build(:account),
      password: "supersecret123"
    }
  end

  def with_password_confirmation(user) do
    Map.put(user, :password_confirmation, user.password)
  end

  def widget_settings_factory do
    %ChatApi.WidgetSettings.WidgetSetting{
      color: "some color",
      subtitle: "some subtitle",
      title: "some title"
    }
  end
end
