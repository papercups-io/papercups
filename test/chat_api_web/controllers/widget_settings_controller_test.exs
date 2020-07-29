defmodule ChatApiWeb.WidgetSettingsControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.WidgetSettings
  alias ChatApi.Accounts

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

  def fixture(:widget_settings) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    {:ok, widget_settings} = WidgetSettings.create_widget_setting(create_attr(account.id))

    widget_settings
  end

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  setup %{conn: conn} do
    account = fixture(:account)
    user = %ChatApi.Users.User{email: "test@example.com", account_id: account.id}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "create_or_update" do
    test "creates widget_settings if none exist", %{authed_conn: authed_conn} do
      settings = %{
        title: "Test title",
        subtitle: "Test subtitle",
        color: "Test color"
      }

      resp =
        put(authed_conn, Routes.widget_settings_path(authed_conn, :create_or_update), %{
          widget_settings: settings
        })

      assert %{
               "title" => "Test title",
               "subtitle" => "Test subtitle",
               "color" => "Test color"
             } = json_response(resp, 200)["data"]

      resp =
        put(authed_conn, Routes.widget_settings_path(authed_conn, :create_or_update), %{
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
