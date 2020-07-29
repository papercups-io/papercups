defmodule ChatApiWeb.WidgetSettingsView do
  use ChatApiWeb, :view
  alias ChatApiWeb.WidgetSettingsView

  def render("index.json", %{widget_settings: widget_settings}) do
    %{data: render_many(widget_settings, WidgetSettingsView, "widget_settings.json")}
  end

  def render("show.json", %{widget_settings: widget_settings}) do
    %{data: render_one(widget_settings, WidgetSettingsView, "widget_settings.json")}
  end

  def render("widget_settings.json", %{widget_settings: widget_settings}) do
    %{
      id: widget_settings.id,
      title: widget_settings.title,
      subtitle: widget_settings.subtitle,
      color: widget_settings.color
    }
  end
end
