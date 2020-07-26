defmodule ChatApiWeb.WidgetConfigController do
  use ChatApiWeb, :controller

  alias ChatApi.WidgetConfigs
  alias ChatApi.WidgetConfigs.WidgetConfig

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    widget_configs = WidgetConfigs.list_widget_configs()
    render(conn, "index.json", widget_configs: widget_configs)
  end

  def create(conn, %{"widget_config" => widget_config_params}) do
    #TOOD Account id shouldn't be passed in #173997813
    with {:ok, %WidgetConfig{} = widget_config} <- WidgetConfigs.create_widget_config(widget_config_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.widget_config_path(conn, :show, widget_config))
      |> render("show.json", widget_config: widget_config)
    end
  end

  @spec update(any, map) :: any
  def createOrUpdate(conn, %{"id" => id, "widget_config" => widget_config_params}) do
    widget_config = WidgetConfigs.create_or_update(id, widget_config_params)
    render(conn, "show.json", widget_config: widget_config)
  end

  def show(conn, %{"id" => id}) do
    widget_config = WidgetConfigs.get_widget_config!(id)
    render(conn, "show.json", widget_config: widget_config)
  end

  def update(conn, %{"id" => id, "widget_config" => widget_config_params}) do
    widget_config = WidgetConfigs.get_widget_config!(id)

    with {:ok, %WidgetConfig{} = widget_config} <- WidgetConfigs.update_widget_config(widget_config, widget_config_params) do
      render(conn, "show.json", widget_config: widget_config)
    end
  end

  def delete(conn, %{"id" => id}) do
    widget_config = WidgetConfigs.get_widget_config!(id)

    with {:ok, %WidgetConfig{}} <- WidgetConfigs.delete_widget_config(widget_config) do
      send_resp(conn, :no_content, "")
    end
  end
end
