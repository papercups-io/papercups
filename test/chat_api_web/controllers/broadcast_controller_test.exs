defmodule ChatApiWeb.BroadcastControllerTest do
  use ChatApiWeb.ConnCase, async: true
  import ChatApi.Factory
  alias ChatApi.Broadcasts.Broadcast

  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    started_at: "2011-05-18T15:01:01Z",
    finished_at: "2011-05-18T15:02:01Z",
    state: "active"
  }
  @invalid_attrs %{name: nil, state: nil}

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    broadcast = insert(:broadcast, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, broadcast: broadcast}
  end

  describe "index" do
    test "lists all broadcasts", %{
      authed_conn: authed_conn,
      broadcast: broadcast
    } do
      resp = get(authed_conn, Routes.broadcast_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [broadcast.id]
    end
  end

  describe "show broadcast" do
    test "shows broadcast by id", %{
      account: account,
      authed_conn: authed_conn
    } do
      broadcast =
        insert(:broadcast, %{
          name: "Another broadcast name",
          account: account
        })

      conn =
        get(
          authed_conn,
          Routes.broadcast_path(authed_conn, :show, broadcast.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's broadcast", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a broadcast
      another_account = insert(:account)

      broadcast =
        insert(:broadcast, %{
          name: "Another broadcast name",
          account: another_account
        })

      # Using the original session, try to delete the new account's broadcast
      conn =
        get(
          authed_conn,
          Routes.broadcast_path(authed_conn, :show, broadcast.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "create broadcast" do
    test "renders broadcast when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      resp =
        post(authed_conn, Routes.broadcast_path(authed_conn, :create),
          broadcast: params_for(:broadcast, account: account, name: "Test Broadcast")
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.broadcast_path(authed_conn, :show, id))
      account_id = account.id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "broadcast",
               "name" => "Test Broadcast"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.broadcast_path(authed_conn, :create), broadcast: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update broadcast" do
    test "renders broadcast when data is valid", %{
      authed_conn: authed_conn,
      broadcast: %Broadcast{id: id} = broadcast
    } do
      conn =
        put(authed_conn, Routes.broadcast_path(authed_conn, :update, broadcast),
          broadcast: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.broadcast_path(authed_conn, :show, id))
      account_id = broadcast.account_id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "name" => "some updated name",
               "description" => "some updated description",
               "started_at" => "2011-05-18T15:01:01Z",
               "finished_at" => "2011-05-18T15:02:01Z",
               "state" => "active"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      broadcast: broadcast
    } do
      conn =
        put(authed_conn, Routes.broadcast_path(authed_conn, :update, broadcast),
          broadcast: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when editing another account's broadcast",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a broadcast
      another_account = insert(:account)

      broadcast =
        insert(:broadcast, %{
          name: "Another broadcast name",
          account: another_account
        })

      # Using the original session, try to update the new account's broadcast
      conn =
        put(
          authed_conn,
          Routes.broadcast_path(authed_conn, :update, broadcast),
          broadcast: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete broadcast" do
    test "deletes chosen broadcast", %{
      authed_conn: authed_conn,
      broadcast: broadcast
    } do
      conn = delete(authed_conn, Routes.broadcast_path(authed_conn, :delete, broadcast))

      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.broadcast_path(authed_conn, :show, broadcast))
      end)
    end

    test "renders 404 when deleting another account's broadcast",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a broadcast
      another_account = insert(:account)

      broadcast =
        insert(:broadcast, %{
          name: "Another broadcast name",
          account: another_account
        })

      # Using the original session, try to delete the new account's broadcast
      conn =
        delete(
          authed_conn,
          Routes.broadcast_path(authed_conn, :delete, broadcast)
        )

      assert json_response(conn, 404)
    end
  end
end
