defmodule ChatApiWeb.UserSettingsControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.Users

  @create_attrs %{
    email_alert_on_new_message: true
  }
  @update_attrs %{
    email_alert_on_new_message: false
  }

  setup %{conn: conn} do
    user = insert(:user)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, user: user}
  end

  describe "update user_settings" do
    test "updates a user's settings", %{authed_conn: authed_conn} do
      resp =
        put(authed_conn, Routes.user_settings_path(authed_conn, :update),
          user_settings: @create_attrs
        )

      assert %{"email_alert_on_new_message" => email_alert_on_new_message} =
               json_response(resp, 200)["data"]

      assert email_alert_on_new_message == @create_attrs.email_alert_on_new_message

      resp =
        put(authed_conn, Routes.user_settings_path(authed_conn, :update),
          user_settings: @update_attrs
        )

      assert %{"email_alert_on_new_message" => email_alert_on_new_message} =
               json_response(resp, 200)["data"]

      assert email_alert_on_new_message == @update_attrs.email_alert_on_new_message
    end
  end

  describe "show user_settings" do
    test "retrieves the user's settings",
         %{authed_conn: authed_conn, user: user} do
      user_settings = Users.get_user_settings(user.id)
      resp = get(authed_conn, Routes.user_settings_path(authed_conn, :show, %{}))

      assert %{"email_alert_on_new_message" => email_alert_on_new_message} =
               json_response(resp, 200)["data"]

      assert email_alert_on_new_message == user_settings.email_alert_on_new_message
    end
  end
end
