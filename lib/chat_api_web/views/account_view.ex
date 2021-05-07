defmodule ChatApiWeb.AccountView do
  use ChatApiWeb, :view

  alias ChatApi.{Utils, Accounts}

  alias ChatApiWeb.{
    AccountView,
    AccountSettingsView,
    UserView,
    WidgetSettingsView,
    WorkingHoursView
  }

  def render("index.json", %{accounts: accounts}) do
    %{data: render_many(accounts, AccountView, "account.json")}
  end

  def render("show.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account.json")}
  end

  def render("create.json", %{account: account}) do
    %{data: render_one(account, AccountView, "basic.json")}
  end

  def render("basic.json", %{account: account}) do
    %{
      object: "account",
      id: account.id,
      company_name: account.company_name,
      company_logo_url: account.company_logo_url,
      time_zone: account.time_zone,
      subscription_plan: account.subscription_plan,
      settings: render_one(account.settings, AccountSettingsView, "account_settings.json"),
      working_hours: render_many(account.working_hours, WorkingHoursView, "working_hours.json"),
      # TODO: not sure if this logic should be handled on the client instead, but this simplifies things for now
      is_outside_working_hours: Accounts.is_outside_working_hours?(account),
      current_minutes_since_midnight:
        Utils.DateTimeUtils.current_minutes_since_midnight(account.time_zone)
    }
  end

  def render("account.json", %{account: account}) do
    %{
      object: "account",
      id: account.id,
      company_name: account.company_name,
      company_logo_url: account.company_logo_url,
      time_zone: account.time_zone,
      subscription_plan: account.subscription_plan,
      settings: render_one(account.settings, AccountSettingsView, "account_settings.json"),
      users: render_many(account.users, UserView, "user.json"),
      widget_settings: render_one(account.widget_settings, WidgetSettingsView, "basic.json"),
      working_hours: render_many(account.working_hours, WorkingHoursView, "working_hours.json"),
      # TODO: not sure if this logic should be handled on the client instead, but this simplifies things for now
      is_outside_working_hours: Accounts.is_outside_working_hours?(account),
      current_minutes_since_midnight:
        Utils.DateTimeUtils.current_minutes_since_midnight(account.time_zone)
    }
  end
end
