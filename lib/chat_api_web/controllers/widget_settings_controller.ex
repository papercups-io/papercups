defmodule ChatApiWeb.WidgetSettingsController do
  use ChatApiWeb, :controller

  alias ChatApi.WidgetSettings
  alias ChatApi.WidgetSettings.WidgetSetting

  action_fallback ChatApiWeb.FallbackController

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"account_id" => account_id}) do
    widget_settings = WidgetSettings.get_settings_by_account(account_id)

    render(conn, "show.json", widget_settings: widget_settings)
  end

  def show(conn, params) do
    conn
    |> put_status(422)
    |> json(%{
      error: %{
        status: 422,
        message: "The account_id is a required parameter",
        received: Map.keys(params)
      }
    })
  end

  @spec update_metadata(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update_metadata(conn, %{"account_id" => account_id, "metadata" => metadata}) do
    with {:ok, widget_settings} <- WidgetSettings.update_widget_metadata(account_id, metadata) do
      render(conn, "update.json", widget_settings: widget_settings)
    end
  end

  def update_metadata(conn, params) do
    conn
    |> put_status(422)
    |> json(%{
      error: %{
        status: 422,
        message: "The following parameters are required: account_id, metadata",
        received: Map.keys(params)
      }
    })
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %{"widget_settings" => attrs} <- params do
      {:ok, widget_settings} =
        WidgetSettings.get_settings_by_account(account_id)
        |> WidgetSettings.update_widget_setting(attrs)

      render(conn, "update.json", widget_settings: widget_settings)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    widget_setting = WidgetSettings.get_widget_setting!(id)

    with {:ok, %WidgetSetting{}} <- WidgetSettings.delete_widget_setting(widget_setting) do
      send_resp(conn, :no_content, "")
    end
  end
end
