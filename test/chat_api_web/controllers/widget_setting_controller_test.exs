defmodule ChatApiWeb.WidgetSettingControllerTest do
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

  def fixture(:widget_setting) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    {:ok, widget_setting} = WidgetSettings.create_widget_setting(create_attr(account.id))

    widget_setting
  end

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    account
  end

  setup %{conn: conn} do
    user = %ChatApi.Users.User{email: "test@example.com"}
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])
    account = fixture(:account)

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all widget_settings", %{authed_conn: authed_conn} do
      conn = get(authed_conn, Routes.widget_setting_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end
end
