defmodule ChatApiWeb.WidgetSettingController do
  use ChatApiWeb, :controller

  alias ChatApi.WidgetSettings
  alias ChatApi.WidgetSettings.WidgetSetting

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    widget_settings = WidgetSettings.list_widget_settings()
    render(conn, "index.json", widget_settings: widget_settings)
  end

  def create_or_update(conn, %{"widget_settings" => widget_settings_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      id = widget_settings_params["id"]
      widget_settings_params = Map.merge(widget_settings_params, %{"account_id" => account_id})
      {:ok, widget_setting} = WidgetSettings.create_or_update(id, widget_settings_params)
      # IO.inspect(widget_setting)
      render(conn, "widget_setting.json", widget_setting: widget_setting)
    end
  end

  def delete(conn, %{"id" => id}) do
    widget_setting = WidgetSettings.get_widget_setting!(id)

    with {:ok, %WidgetSetting{}} <- WidgetSettings.delete_widget_setting(widget_setting) do
      send_resp(conn, :no_content, "")
    end
  end
end
