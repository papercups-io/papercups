defmodule ChatApi.Factory do
  use ExMachina.Ecto, repo: ChatApi.Repo

  # Factories
  def account_factory do
    %ChatApi.Accounts.Account{
      company_name: sequence("some company_name")
    }
  end

  def widget_settings_factory do
    %ChatApi.WidgetSettings.WidgetSetting{
      color: "some color",
      subtitle: "some subtitle",
      title: "some title"
    }
  end
end
