defmodule ChatApiWeb.AccountView do
  use ChatApiWeb, :view

  alias ChatApiWeb.{
    AccountView,
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
      id: account.id,
      company_name: account.company_name,
      time_zone: account.time_zone,
      subscription_plan: account.subscription_plan,
      working_hours: render_many(account.working_hours, WorkingHoursView, "working_hours.json")
    }
  end

  def render("account.json", %{account: account}) do
    %{
      id: account.id,
      company_name: account.company_name,
      time_zone: account.time_zone,
      subscription_plan: account.subscription_plan,
      users: render_many(account.users, UserView, "user.json"),
      widget_settings: render_one(account.widget_settings, WidgetSettingsView, "basic.json"),
      working_hours: render_many(account.working_hours, WorkingHoursView, "working_hours.json")
    }
  end
end
