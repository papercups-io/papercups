defmodule ChatApiWeb.TwilioControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "update" do
    # test "returns existing widget_settings",
    #      %{authed_conn: authed_conn, account: account} do

    #   resp =
    #     put(authed_conn, Routes.widget_settings_path(authed_conn, :update), %{
    #       widget_settings: settings
    #     })

    # end
  end
end
