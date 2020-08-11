defmodule ChatApiWeb.WidgetSettingsController do
  use ChatApiWeb, :controller

  alias ChatApi.WidgetSettings
  alias ChatApi.WidgetSettings.WidgetSetting

  action_fallback ChatApiWeb.FallbackController

  def show(conn, %{"account_id" => account_id}) do
    widget_settings = WidgetSettings.get_settings_by_account(account_id)

    render(conn, "show.json", widget_settings: widget_settings)
  end

  def update_metadata(conn, payload) do
    with %{"account_id" => account_id, "metadata" => metadata} <- payload do
      {:ok, widget_settings} = WidgetSettings.update_widget_metadata(account_id, metadata)

      render(conn, "update.json", widget_settings: widget_settings)
    end
  end

  def create_or_update(conn, %{"widget_settings" => widget_settings_params}) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      widget_settings_params = Map.merge(widget_settings_params, %{"account_id" => account_id})
      {:ok, widget_settings} = WidgetSettings.create_or_update(account_id, widget_settings_params)

      render(conn, "update.json", widget_settings: widget_settings)
    end
  end

  def delete(conn, %{"id" => id}) do
    widget_setting = WidgetSettings.get_widget_setting!(id)

    with {:ok, %WidgetSetting{}} <- WidgetSettings.delete_widget_setting(widget_setting) do
      send_resp(conn, :no_content, "")
    end
  end
end
