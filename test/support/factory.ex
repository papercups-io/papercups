defmodule ChatApi.Factory do
  use ExMachina.Ecto, repo: ChatApi.Repo

  # Factories
  def account_factory do
    %ChatApi.Accounts.Account{
      company_name: sequence("some company_name"),
      settings: %{}
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

  def canned_response_factory do
    %ChatApi.CannedResponses.CannedResponse{
      account: build(:account),
      name: sequence("some name"),
      content: sequence("some content")
    }
  end

  def company_factory do
    %ChatApi.Companies.Company{
      account: build(:account),
      name: "Test Inc"
    }
  end

  def conversation_factory do
    %ChatApi.Conversations.Conversation{
      account: build(:account),
      customer: build(:customer),
      status: "open",
      source: "chat"
    }
  end

  def customer_factory do
    %ChatApi.Customers.Customer{
      first_seen: ~D[2020-01-01],
      last_seen_at: ~U[2020-01-05 00:00:00Z],
      email: sequence(:email, &"test-#{&1}@test.com"),
      account: build(:account),
      company: build(:company),
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

  def file_factory do
    %ChatApi.Files.FileUpload{
      account: build(:account),
      filename: sequence("some filename"),
      file_url: sequence("https://image.jpg"),
      content_type: "image/png"
    }
  end

  def github_authorization_factory do
    %ChatApi.Github.GithubAuthorization{
      access_token: "some access_token",
      refresh_token: "some refresh_token",
      token_type: "some token_type",
      scope: "some scope",
      github_installation_id: "some github_installation_id",
      account: build(:account),
      user: build(:user)
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

  def mattermost_authorization_factory do
    %ChatApi.Mattermost.MattermostAuthorization{
      access_token: "some access_token",
      account: build(:account),
      user: build(:user)
    }
  end

  def issue_factory do
    %ChatApi.Issues.Issue{
      title: sequence("some title"),
      body: "some body",
      state: "unstarted",
      account: build(:account),
      creator: build(:user)
    }
  end

  def lambda_factory do
    %ChatApi.Lambdas.Lambda{
      name: sequence("some name"),
      description: "some description",
      status: "inactive",
      code: "var message = 'Hello world!';",
      language: "javascript",
      runtime: "nodejs14.x",
      account: build(:account),
      creator: build(:user)
    }
  end

  def message_factory do
    %ChatApi.Messages.Message{
      account: build(:account),
      conversation: build(:conversation),
      customer: build(:customer),
      user: build(:user),
      body: "some message body",
      source: "chat"
    }
  end

  def note_factory do
    account = build(:account)

    %ChatApi.Notes.Note{
      body: "some customer note",
      customer: build(:customer),
      account: account,
      author: build(:user, account: account)
    }
  end

  def slack_authorization_factory do
    %ChatApi.SlackAuthorizations.SlackAuthorization{
      access_token: "some access_token",
      app_id: sequence(:app_id, &"some app_id #{&1}"),
      authed_user_id: sequence(:authed_user_id, &"some authed_user_id #{&1}"),
      bot_user_id: sequence(:bot_user_id, &"some bot_user_id #{&1}"),
      channel: "#test",
      channel_id: sequence(:channel_id, &"some channel_id #{&1}"),
      configuration_url: "some configuration_url",
      scope: "some scope",
      team_id: sequence(:team_id, &"some team_id #{&1}"),
      team_name: sequence(:team_name, &"some team_name #{&1}"),
      token_type: "some token_type",
      webhook_url: "some webhook_url",
      type: "reply",
      account: build(:account)
    }
  end

  def twilio_authorization_factory do
    %ChatApi.Twilio.TwilioAuthorization{
      twilio_auth_token: "some auth token",
      twilio_account_sid: "some account id",
      from_phone_number: "some phone number",
      account: build(:account),
      user: build(:user)
    }
  end

  def slack_conversation_thread_factory do
    %ChatApi.SlackConversationThreads.SlackConversationThread{
      account: build(:account),
      conversation: build(:conversation),
      slack_thread_ts: sequence("1234.56789"),
      slack_channel: "#test"
    }
  end

  def tag_factory do
    %ChatApi.Tags.Tag{
      account: build(:account),
      name: sequence("some name")
    }
  end

  def conversation_tag_factory do
    %ChatApi.Tags.ConversationTag{
      account: build(:account),
      conversation: build(:conversation),
      tag: build(:tag),
      creator: build(:user)
    }
  end

  def customer_tag_factory do
    %ChatApi.Tags.CustomerTag{
      account: build(:account),
      customer: build(:customer),
      tag: build(:tag)
    }
  end

  def user_invitation_factory do
    %ChatApi.UserInvitations.UserInvitation{
      account: build(:account),
      expires_at: DateTime.add(DateTime.utc_now(), :timer.hours(168), :millisecond)
    }
  end

  def user_factory do
    %ChatApi.Users.User{
      email: sequence(:email, &"company_name-#{&1}@example.com"),
      account: build(:account),
      password: "supersecret123"
    }
  end

  def user_settings_factory do
    %ChatApi.Users.UserSettings{
      user: build(:user),
      email_alert_on_new_message: true
    }
  end

  def user_profile_factory do
    %ChatApi.Users.UserProfile{
      user: build(:user),
      display_name: "Test User",
      full_name: "Testy McTesterson",
      profile_photo_url: "https://via.placeholder.com/100x100"
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
