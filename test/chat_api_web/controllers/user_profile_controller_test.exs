defmodule ChatApiWeb.UserProfileControllerTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.{Accounts, Users, Repo}
  alias ChatApi.Users.User

  @password "supersecret123"

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

  def user_profile_fixture(attrs \\ %{}) do
    {:ok, user_profile} =
      attrs
      |> Enum.into(attrs)
      |> Users.create_user_profile()

    user_profile
  end

  setup %{conn: conn} do
    {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

    user =
      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        password: @password,
        password_confirmation: @password,
        account_id: account.id
      })
      |> Repo.insert!()

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, user: user}
  end

  describe "create_or_update user_profile" do
    test "creates or updates a user's profile", %{
      authed_conn: authed_conn
    } do
      resp =
        put(authed_conn, Routes.user_profile_path(authed_conn, :create_or_update),
          user_profile: @create_attrs
        )

      assert %{"display_name" => display_name, "full_name" => full_name} =
               json_response(resp, 200)["data"]

      assert display_name == @create_attrs.display_name
      assert full_name == @create_attrs.full_name

      resp =
        put(authed_conn, Routes.user_profile_path(authed_conn, :create_or_update),
          user_profile: @update_attrs
        )

      assert %{"display_name" => display_name, "full_name" => full_name} =
               json_response(resp, 200)["data"]

      assert display_name == @update_attrs.display_name
      assert full_name == @update_attrs.full_name
    end
  end

  describe "show user_profile" do
    test "retrieves the user's profile", %{authed_conn: authed_conn, user: user} do
      attrs = Map.merge(@create_attrs, %{user_id: user.id})
      user_profile = user_profile_fixture(attrs)
      resp = get(authed_conn, Routes.user_profile_path(authed_conn, :show, %{}))

      assert %{"display_name" => display_name, "full_name" => full_name} =
               json_response(resp, 200)["data"]

      assert display_name == user_profile.display_name
      assert full_name == user_profile.full_name
    end
  end
end
