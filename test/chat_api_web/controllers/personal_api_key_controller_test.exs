defmodule ChatApiWeb.PersonalApiKeyControllerTest do
  use ChatApiWeb.ConnCase

  setup %{conn: conn} do
    account = account_fixture()
    user = user_fixture(account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, user: user}
  end

  describe "index" do
    test "lists all personal_api_keys", %{authed_conn: authed_conn, user: user} do
      conn = get(authed_conn, Routes.personal_api_key_path(authed_conn, :index))
      assert json_response(conn, 200)["data"] == []

      personal_api_key = personal_api_key_fixture(user, %{label: "Test API Key"})
      token = personal_api_key.value

      conn = get(authed_conn, Routes.personal_api_key_path(authed_conn, :index))
      assert [%{"value" => ^token}] = json_response(conn, 200)["data"]
    end
  end
end
