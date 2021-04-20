defmodule ChatApiWeb.GithubControllerTest do
  use ChatApiWeb.ConnCase

  import ChatApi.Factory

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account, role: "admin")
    authorization = insert(:github_authorization, account: account, user: user)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok,
     conn: conn,
     authed_conn: authed_conn,
     account: account,
     authorization: authorization,
     user: user}
  end

  describe "authorization" do
    test "gets the github authorization", %{
      authed_conn: authed_conn,
      authorization: authorization
    } do
      resp = get(authed_conn, Routes.github_path(authed_conn, :authorization))
      expected_authorization_id = authorization.id

      assert %{"id" => ^expected_authorization_id} = json_response(resp, 200)["data"]
    end
  end
end
