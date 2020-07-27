defmodule ChatApiWeb.WidgetSettingView do
  use ChatApiWeb, :view
  alias ChatApiWeb.WidgetSettingView

  def render("index.json", %{widget_settings: widget_settings}) do
    %{data: render_many(widget_settings, WidgetSettingView, "widget_setting.json")}
  end

  def render("show.json", %{widget_setting: widget_setting}) do
    %{data: render_one(widget_setting, WidgetSettingView, "widget_setting.json")}
  end

  def render("widget_setting.json", %{widget_setting: widget_setting}) do
    %{id: widget_setting.id,
      title: widget_setting.title,
      subtitle: widget_setting.subtitle,
      color: widget_setting.color}
  end
end
