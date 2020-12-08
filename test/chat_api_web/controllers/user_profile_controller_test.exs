defmodule ChatApiWeb.UserProfileControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory
  alias ChatApi.Users

  @create_attrs %{
    display_name: "some display_name",
    full_name: "some full_name",
    profile_photo_url: "some profile_photo_url"
  }
  @update_attrs %{
    display_name: "some updated display_name",
    full_name: "some updated full_name",
    profile_photo_url: "some updated profile_photo_url"
  }

  setup %{conn: conn} do
    user = insert(:user)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, user: user}
  end

  describe "update user_profile" do
    test "updates a user's profile",
         %{authed_conn: authed_conn} do
      resp =
        put(authed_conn, Routes.user_profile_path(authed_conn, :update),
          user_profile: @create_attrs
        )

      assert %{"display_name" => display_name, "full_name" => full_name} =
               json_response(resp, 200)["data"]

      assert display_name == @create_attrs.display_name
      assert full_name == @create_attrs.full_name

      resp =
        put(authed_conn, Routes.user_profile_path(authed_conn, :update),
          user_profile: @update_attrs
        )

      assert %{"display_name" => display_name, "full_name" => full_name} =
               json_response(resp, 200)["data"]

      assert display_name == @update_attrs.display_name
      assert full_name == @update_attrs.full_name
    end
  end

  describe "show user_profile" do
    test "retrieves the user's profile given valid user id", %{
      authed_conn: authed_conn,
      user: user
    } do
      user_profile = Users.get_user_profile(user.id)
      resp = get(authed_conn, Routes.user_profile_path(authed_conn, :show, %{}))

      assert %{"display_name" => display_name, "full_name" => full_name, "object" => "user"} =
               json_response(resp, 200)["data"]

      assert display_name == user_profile.display_name
      assert full_name == user_profile.full_name
    end
  end
end
