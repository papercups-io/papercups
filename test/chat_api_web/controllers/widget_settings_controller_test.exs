defmodule ChatApiWeb.WidgetSettingsControllerTest do
  use ChatApiWeb.ConnCase, async: true

  alias ChatApi.WidgetSettings

  def create_attr(account_id) do
    %{
      color: "some color",
      subtitle: "some subtitle",
      title: "some title",
      account_id: account_id
    }
  end

  def update_attrs(account_id) do
    %{
      color: "some updated color",
      subtitle: "some updated subtitle",
      title: "some updated title",
      account_id: account_id
    }
  end

  setup %{conn: conn} do
    account = account_fixture()
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "update" do
    test "returns existing widget_settings", %{authed_conn: authed_conn, account: account} do
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
               "title" => "Test title",
               "subtitle" => "Test subtitle",
               "color" => "Test color"
             } = json_response(resp, 200)["data"]

      resp =
        put(authed_conn, Routes.widget_settings_path(authed_conn, :update), %{
          widget_settings: %{color: "Updated color"}
        })

      assert %{
               "title" => "Test title",
               "subtitle" => "Test subtitle",
               "color" => "Updated color"
             } = json_response(resp, 200)["data"]
    end
  end
end
