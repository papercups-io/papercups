defmodule ChatApi.Factory do
  use ExMachina.Ecto, repo: ChatApi.Repo

  # Factories
  def account_factory do
    %ChatApi.Accounts.Account{
      company_name: sequence("some company_name")
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

  def widget_settings_factory do
    %ChatApi.WidgetSettings.WidgetSetting{
      color: "some color",
      subtitle: "some subtitle",
      title: "some title"
    }
  end

  def user_factory do
    %ChatApi.Users.User{
      email: sequence(:email, &"company_name-#{&1}@example.com"),
      account: build(:account),
      password: "supersecret123"
    }
  end
end
