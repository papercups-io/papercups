defmodule ChatApiWeb.UserSettingsView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UserSettingsView

  def render("index.json", %{user_settings: user_settings}) do
    %{data: render_many(user_settings, UserSettingsView, "user_settings.json")}
  end

  def render("show.json", %{user_settings: user_settings}) do
    %{data: render_one(user_settings, UserSettingsView, "user_settings.json")}
  end

  def render("user_settings.json", %{user_settings: user_settings}) do
    %{
      id: user_settings.id,
      user_id: user_settings.user_id,
      email_alert_on_new_message: user_settings.email_alert_on_new_message
    }
  end
end
