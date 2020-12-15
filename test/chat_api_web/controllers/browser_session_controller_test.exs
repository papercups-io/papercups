defmodule ChatApiWeb.BrowserSessionControllerTest do
  use ChatApiWeb.ConnCase

  import ChatApi.Factory
  alias ChatApi.BrowserSessions.BrowserSession

  @create_attrs %{
    finished_at: "2010-04-17T14:00:00Z",
    metadata: %{},
    started_at: "2010-04-17T14:00:00Z"
  }
  @update_attrs %{
    finished_at: "2011-05-18T15:01:01Z",
    metadata: %{},
    started_at: "2011-05-18T15:01:01Z"
  }
  @invalid_attrs %{
    account_id: nil,
    customer_id: nil,
    finished_at: nil,
    metadata: nil,
    started_at: nil
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account, email: "test@example.com")
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all browser_sessions", %{authed_conn: authed_conn} do
      conn = get(authed_conn, Routes.browser_session_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create browser_session" do
    test "renders browser_session when data is valid", %{
      conn: conn,
      authed_conn: authed_conn,
      account: account
    } do
      attrs = Map.merge(@create_attrs, %{account_id: account.id})
      conn = post(conn, Routes.browser_session_path(conn, :create), browser_session: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(authed_conn, Routes.browser_session_path(authed_conn, :show, id))

      assert %{
               "id" => ^id,
               "object" => "browser_session",
               "finished_at" => "2010-04-17T14:00:00Z",
               "metadata" => %{},
               "started_at" => "2010-04-17T14:00:00Z"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.browser_session_path(conn, :create), browser_session: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update browser_session" do
    setup [:create_browser_session]

    test "renders browser_session when data is valid", %{
      authed_conn: authed_conn,
      browser_session: %BrowserSession{id: id} = browser_session
    } do
      conn =
        put(authed_conn, Routes.browser_session_path(authed_conn, :update, browser_session),
          browser_session: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.browser_session_path(authed_conn, :show, id))

      assert %{
               "id" => ^id,
               "object" => "browser_session",
               "finished_at" => "2011-05-18T15:01:01Z",
               "metadata" => %{},
               "started_at" => "2011-05-18T15:01:01Z"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      browser_session: browser_session
    } do
      conn =
        put(authed_conn, Routes.browser_session_path(authed_conn, :update, browser_session),
          browser_session: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete browser_session" do
    setup [:create_browser_session]

    test "deletes chosen browser_session", %{
      authed_conn: authed_conn,
      browser_session: browser_session
    } do
      conn =
        delete(authed_conn, Routes.browser_session_path(authed_conn, :delete, browser_session))

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(authed_conn, Routes.browser_session_path(authed_conn, :show, browser_session))
      end
    end
  end

  defp create_browser_session(%{account: account}) do
    browser_session = insert(:browser_session, account: account)

    %{browser_session: browser_session}
  end
end
