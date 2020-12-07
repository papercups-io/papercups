defmodule ChatApi.UsersTest do
  use ChatApi.DataCase, async: true
  @moduledoc false

  import ChatApi.Factory

  alias ChatApi.Users
  alias ChatApi.Users.User
  alias ChatApi.Users.UserSettings

  describe "profiles" do
    alias ChatApi.Users.UserProfile

    @valid_attrs %{
      display_name: "some display_name",
      full_name: "some full_name",
      profile_photo_url: "some profile_photo_url"
    }
    @update_attrs %{
      display_name: "some updated display_name",
      full_name: "some updated full_name",
      profile_photo_url: "some updated profile_photo_url"
    }

    setup do
      {:ok, user: insert(:user)}
    end

    test "set_admin_role/1 sets the user's role to 'admin'", %{user: user} do
      assert {:ok, %User{role: "admin"}} = Users.set_admin_role(user)
    end

    test "set_user_role/1 sets the user's role to 'user'", %{user: user} do
      assert {:ok, %User{role: "user"}} = Users.set_user_role(user)
    end

    test "disable_user/1 disables the user", %{user: user} do
      assert {:ok, %User{disabled_at: disabled_at}} = Users.disable_user(user)
      assert disabled_at != nil
    end

    test "archive_user/1 archives the user", %{user: user} do
      assert {:ok, %User{archived_at: archived_at}} = Users.archive_user(user)
      assert archived_at != nil
    end

    test "get_user_profile/1 returns the user_profile with given valid user id",
         %{user: user} do
      assert %UserProfile{user_id: id} = Users.get_user_profile(user.id)

      assert id == user.id
    end

    test "update_profile/2 with valid data updates the user_profile",
         %{user: user} do
      assert {:ok, %UserProfile{} = user_profile} =
               Users.update_user_profile(user.id, @valid_attrs)

      assert user_profile.display_name == @valid_attrs.display_name

      assert {:ok, %UserProfile{} = user_profile} =
               Users.update_user_profile(user.id, @update_attrs)

      assert user_profile.display_name == @update_attrs.display_name
    end

    test "create_user/1 create user with default setting & profile",
         %{user: user} do
      assert %UserProfile{} = Users.get_user_profile(user.id)
      assert %UserSettings{} = Users.get_user_settings(user.id)
    end
  end

  describe "user_settings" do
    @valid_attrs %{email_alert_on_new_message: true}
    @update_attrs %{email_alert_on_new_message: false}

    setup do
      {:ok, user: insert(:user)}
    end

    test "get_user_settings/1 returns the user_settings with given valid user id", %{user: user} do
      %UserSettings{user_id: user_id} = Users.get_user_settings(user.id)

      assert user_id == user.id
    end

    test "update_user_settings/2 with valid data updates the user_settings",
         %{user: user} do
      assert {:ok, %UserSettings{} = user_settings} =
               Users.update_user_settings(user.id, @valid_attrs)

      assert user_settings.email_alert_on_new_message == true

      assert {:ok, %UserSettings{} = user_settings} =
               Users.update_user_settings(user.id, @update_attrs)

      assert user_settings.email_alert_on_new_message == false
    end
  end
end
