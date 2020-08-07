defmodule ChatApiWeb.WidgetSettingsView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{AccountView, WidgetSettingsView}

  def render("show.json", %{widget_settings: widget_settings}) do
    %{data: render_one(widget_settings, WidgetSettingsView, "expanded.json")}
  end

  def render("update.json", %{widget_settings: widget_settings}) do
    %{data: render_one(widget_settings, WidgetSettingsView, "basic.json")}
  end

  def render("basic.json", %{widget_settings: widget_settings}) do
    %{
      id: widget_settings.id,
      title: widget_settings.title,
      subtitle: widget_settings.subtitle,
      color: widget_settings.color,
      greeting: widget_settings.greeting,
      new_message_placeholder: widget_settings.new_message_placeholder,
      base_url: widget_settings.base_url
    }
  end

  def render("expanded.json", %{widget_settings: widget_settings}) do
    %{
      title: widget_settings.title,
      subtitle: widget_settings.subtitle,
      color: widget_settings.color,
      greeting: widget_settings.greeting,
      new_message_placeholder: widget_settings.new_message_placeholder,
      base_url: widget_settings.base_url,
      account: render_one(widget_settings.account, AccountView, "basic.json")
    }
  end
end
