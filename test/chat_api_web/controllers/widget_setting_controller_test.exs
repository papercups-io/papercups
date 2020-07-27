defmodule ChatApiWeb.WidgetSettingControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.WidgetSettings
  alias ChatApi.WidgetSettings.WidgetSetting
  alias ChatApi.Accounts
  @invalid_attrs %{color: nil, subtitle: nil, title: nil}

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

  describe "create widget_setting" do
    test "renders widget_setting when data is valid", %{authed_conn: authed_conn, account: account} do

      conn =
        post(authed_conn, Routes.widget_setting_path(authed_conn, :create),
          widget_setting: create_attr(account.id)
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      # conn = get(authed_conn, Routes.widget_setting_path(authed_conn, :show, id))

      # assert %{
      #          "id" => id,
      #          "color" => "some color",
      #          "subtitle" => "some subtitle",
      #          "title" => "some title"
      #        } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.widget_setting_path(authed_conn, :create),
          widget_setting: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update widget_setting" do
    setup [:create_widget_setting]

    test "renders widget_setting when data is valid", %{
      authed_conn: authed_conn,
      widget_setting: %WidgetSetting{id: id} = widget_setting,
      account: account
    } do
      conn =
        put(authed_conn, Routes.widget_setting_path(authed_conn, :update, widget_setting),
          widget_setting: update_attrs(account.id)
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.widget_setting_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "color" => "some updated color",
               "subtitle" => "some updated subtitle",
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      widget_setting: widget_setting
    } do
      conn =
        put(authed_conn, Routes.widget_setting_path(authed_conn, :update, widget_setting),
          widget_setting: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete widget_setting" do
    setup [:create_widget_setting]

    test "deletes chosen widget_setting", %{authed_conn: authed_conn, widget_setting: widget_setting} do
      conn = delete(authed_conn, Routes.widget_setting_path(authed_conn, :delete, widget_setting))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.widget_setting_path(authed_conn, :show, widget_setting))
      end
    end
  end

  defp create_widget_setting(_) do
    widget_setting = fixture(:widget_setting)
    %{widget_setting: widget_setting}
  end
end
