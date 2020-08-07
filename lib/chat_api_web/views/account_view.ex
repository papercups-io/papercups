defmodule ChatApiWeb.AccountView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{AccountView, UserView, WidgetSettingsView}

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
      company_name: account.company_name
    }
  end

  def render("account.json", %{account: account}) do
    %{
      id: account.id,
      company_name: account.company_name,
      users: render_many(account.users, UserView, "user.json"),
      widget_settings: render_one(account.widget_settings, WidgetSettingsView, "basic.json")
    }
  end
end
