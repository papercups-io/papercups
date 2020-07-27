defmodule ChatApiWeb.WidgetSettingController do
  use ChatApiWeb, :controller

  alias ChatApi.WidgetSettings
  alias ChatApi.WidgetSettings.WidgetSetting

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    widget_settings = WidgetSettings.list_widget_settings()
    render(conn, "index.json", widget_settings: widget_settings)
  end

  def create(conn, %{"widget_setting" => widget_setting_params}) do
    #TOOD Account id shouldn't be passed in #173997813
    with {:ok, %WidgetSetting{} = widget_setting} <- WidgetSettings.create_widget_setting(widget_setting_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.widget_setting_path(conn, :show, widget_setting))
      |> render("show.json", widget_setting: widget_setting)
    end
  end

  @spec update(any, map) :: any
  def createOrUpdate(conn, %{"id" => id, "widget_setting" => widget_setting_params}) do
    widget_setting = WidgetSettings.create_or_update(id, widget_setting_params)
    render(conn, "show.json", widget_setting: widget_setting)
  end

  def show(conn, %{"id" => id}) do
    widget_setting = WidgetSettings.get_widget_setting!(id)
    render(conn, "show.json", widget_setting: widget_setting)
  end

  def update(conn, %{"id" => id, "widget_setting" => widget_setting_params}) do
    widget_setting = WidgetSettings.get_widget_setting!(id)

    with {:ok, %WidgetSetting{} = widget_setting} <- WidgetSettings.update_widget_setting(widget_setting, widget_setting_params) do
      render(conn, "show.json", widget_setting: widget_setting)
    end
  end

  def delete(conn, %{"id" => id}) do
    widget_setting = WidgetSettings.get_widget_setting!(id)

    with {:ok, %WidgetSetting{}} <- WidgetSettings.delete_widget_setting(widget_setting) do
      send_resp(conn, :no_content, "")
    end
  end
end
