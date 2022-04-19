defmodule ChatApiWeb.WidgetSettingsController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, WidgetSettings}
  alias ChatApi.WidgetSettings.WidgetSetting

  action_fallback(ChatApiWeb.FallbackController)

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"account_id" => account_id} = params) do
    # TODO: should we create a Phoenix Plug for this pattern?
    # Or just improve error handling with `foreign_key_constraint(:account_id)`
    if Accounts.exists?(account_id) do
      filters = ensure_inbox_filter_included(account_id, params)
      widget_settings = WidgetSettings.get_settings_by_account!(account_id, filters)

      render(conn, "show.json", widget_settings: widget_settings)
    else
      send_account_not_found_error(conn, account_id)
    end
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
  def update_metadata(conn, %{"account_id" => account_id, "metadata" => metadata} = params) do
    if Accounts.exists?(account_id) do
      with filters <- ensure_inbox_filter_included(account_id, params),
           {:ok, widget_settings} <-
             WidgetSettings.update_widget_metadata(account_id, metadata, filters) do
        render(conn, "update.json", widget_settings: widget_settings)
      end
    else
      send_account_not_found_error(conn, account_id)
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
  def update(conn, %{"widget_settings" => params}) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      filters = ensure_inbox_filter_included(account_id, params)

      {:ok, widget_settings} =
        account_id
        |> WidgetSettings.get_settings_by_account!(filters)
        |> WidgetSettings.update_widget_setting(params)

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

  @spec send_account_not_found_error(Plug.Conn.t(), binary()) :: Plug.Conn.t()
  defp send_account_not_found_error(conn, account_id) do
    conn
    |> put_status(404)
    |> json(%{
      error: %{
        status: 404,
        message: "No account found with ID: #{account_id}. Are you pointing at the correct host?",
        host: System.get_env("BACKEND_URL") || "localhost"
      }
    })
  end

  defp ensure_inbox_filter_included(account_id, params) do
    case params do
      %{"inbox_id" => inbox_id} when is_binary(inbox_id) ->
        params

      _ ->
        Map.merge(params, %{
          "inbox_id" => ChatApi.Inboxes.get_account_primary_inbox_id(account_id)
        })
    end
  end
end
