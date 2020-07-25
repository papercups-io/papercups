defmodule ChatApiWeb.WidgetConfigControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.WidgetConfigs
  alias ChatApi.WidgetConfigs.WidgetConfig
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

  def fixture(:widget_config) do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
    {:ok, widget_config} = WidgetConfigs.create_widget_config(create_attr(account.id))

    widget_config
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
    test "lists all widget_configs", %{authed_conn: authed_conn} do
      conn = get(authed_conn, Routes.widget_config_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create widget_config" do
    test "renders widget_config when data is valid", %{authed_conn: authed_conn, account: account} do

      conn =
        post(authed_conn, Routes.widget_config_path(authed_conn, :create),
          widget_config: create_attr(account.id)
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      # conn = get(authed_conn, Routes.widget_config_path(authed_conn, :show, id))

      # assert %{
      #          "id" => id,
      #          "color" => "some color",
      #          "subtitle" => "some subtitle",
      #          "title" => "some title"
      #        } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.widget_config_path(authed_conn, :create),
          widget_config: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update widget_config" do
    setup [:create_widget_config]

    test "renders widget_config when data is valid", %{
      authed_conn: authed_conn,
      widget_config: %WidgetConfig{id: id} = widget_config,
      account: account
    } do
      conn =
        put(authed_conn, Routes.widget_config_path(authed_conn, :update, widget_config),
          widget_config: update_attrs(account.id)
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.widget_config_path(authed_conn, :show, id))

      assert %{
               "id" => id,
               "color" => "some updated color",
               "subtitle" => "some updated subtitle",
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      widget_config: widget_config
    } do
      conn =
        put(authed_conn, Routes.widget_config_path(authed_conn, :update, widget_config),
          widget_config: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete widget_config" do
    setup [:create_widget_config]

    test "deletes chosen widget_config", %{authed_conn: authed_conn, widget_config: widget_config} do
      conn = delete(authed_conn, Routes.widget_config_path(authed_conn, :delete, widget_config))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.widget_config_path(authed_conn, :show, widget_config))
      end
    end
  end

  defp create_widget_config(_) do
    widget_config = fixture(:widget_config)
    %{widget_config: widget_config}
  end
end
