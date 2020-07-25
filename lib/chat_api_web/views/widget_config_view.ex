defmodule ChatApiWeb.WidgetConfigView do
  use ChatApiWeb, :view
  alias ChatApiWeb.WidgetConfigView

  def render("index.json", %{widget_configs: widget_configs}) do
    %{data: render_many(widget_configs, WidgetConfigView, "widget_config.json")}
  end

  def render("show.json", %{widget_config: widget_config}) do
    %{data: render_one(widget_config, WidgetConfigView, "widget_config.json")}
  end

  def render("widget_config.json", %{widget_config: widget_config}) do
    %{id: widget_config.id,
      title: widget_config.title,
      subtitle: widget_config.subtitle,
      color: widget_config.color}
  end
end
