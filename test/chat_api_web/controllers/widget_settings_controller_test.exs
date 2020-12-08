defmodule ChatApiWeb.WidgetSettingsControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.WidgetSettings

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "update" do
    test "returns existing widget_settings",
         %{authed_conn: authed_conn, account: account} do
      assert %WidgetSettings.WidgetSetting{} = WidgetSettings.get_settings_by_account(account.id)

      settings = %{
        title: "Test title",
        subtitle: "Test subtitle",
        color: "Test color"
      }

      resp =
        put(authed_conn, Routes.widget_settings_path(authed_conn, :update), %{
          widget_settings: settings
        })

      assert %{
               "object" => "widget_settings",
               "title" => "Test title",
               "subtitle" => "Test subtitle",
               "color" => "Test color"
             } = json_response(resp, 200)["data"]

      resp =
        put(authed_conn, Routes.widget_settings_path(authed_conn, :update), %{
          widget_settings: %{color: "Updated color"}
        })

      assert %{
               "object" => "widget_settings",
               "title" => "Test title",
               "subtitle" => "Test subtitle",
               "color" => "Updated color"
             } = json_response(resp, 200)["data"]
    end
  end
end
