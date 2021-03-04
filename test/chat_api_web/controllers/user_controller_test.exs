defmodule ChatApiWeb.UserControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.{Users, Repo}

  setup %{conn: conn} do
    user = insert(:user)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, user: user}
  end

  describe "delete user" do
    test "deletes user",
         %{authed_conn: authed_conn, user: user} do
      resp = delete(authed_conn, Routes.user_path(authed_conn, :delete, user.id))
      assert Repo.get(Users.User, user.id) == nil
      assert %{"ok" => true} = json_response(resp, 200)["data"]
    end

    test "returns 403 (forbidden) when trying to delete other users", %{
      authed_conn: authed_conn,
      user: user
    } do
      resp = delete(authed_conn, Routes.user_path(authed_conn, :delete, user.id + 1))
      assert resp.status == 403
    end
  end
end
