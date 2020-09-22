defmodule ChatApi.UsersTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, Users}
  alias ChatApi.Users.User

  describe "profiles" do
    alias ChatApi.Users.UserProfile

    @password "supersecret123"

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
    @invalid_attrs %{display_name: nil, full_name: nil, profile_photo_url: nil, user_id: nil}

    def user_profile_fixture(attrs \\ %{}) do
      {:ok, user_profile} =
        attrs
        |> Enum.into(attrs)
        |> Users.create_user_profile()

      user_profile
    end

    setup do
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

      {:ok, user: user, account: account}
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

    test "get_user_profile/1 returns the user_profile with given id", %{user: user} do
      user_profile = user_profile_fixture(%{user_id: user.id})

      expected =
        Users.get_user_profile(user.id)
        |> Map.take([:display_name, :full_name, :profile_photo_url])

      actual = Map.take(user_profile, [:display_name, :full_name, :profile_photo_url])

      assert expected == actual
    end

    test "create_user_profile/1 with valid data creates a user_profile", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id})
      assert {:ok, %UserProfile{} = user_profile} = Users.create_user_profile(attrs)

      assert user_profile.display_name == "some display_name"
      assert user_profile.full_name == "some full_name"
      assert user_profile.profile_photo_url == "some profile_photo_url"
    end

    test "create_user_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_user_profile(@invalid_attrs)
    end

    test "create_or_update_profile/2 with valid data creates or updates the user_profile", %{
      user: user
    } do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id})

      assert {:ok, %UserProfile{} = user_profile} = Users.create_or_update_profile(user.id, attrs)

      assert user_profile.display_name == "some display_name"

      assert {:ok, %UserProfile{} = user_profile} =
               Users.create_or_update_profile(user.id, @update_attrs)

      assert user_profile.display_name == "some updated display_name"
    end
  end

  describe "user_settings" do
    alias ChatApi.Users.UserSettings

    @password "supersecret123"

    @valid_attrs %{email_alert_on_new_message: true}
    @update_attrs %{email_alert_on_new_message: false}
    @invalid_attrs %{email_alert_on_new_message: nil}

    def user_settings_fixture(attrs \\ %{}) do
      {:ok, user_settings} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Users.create_user_settings()

      user_settings
    end

    setup do
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

      {:ok, user: user, account: account}
    end

    test "get_user_settings/1 returns the user_settings with given id", %{user: user} do
      user_settings = user_settings_fixture(%{user_id: user.id})

      assert Users.get_user_settings(user.id) == user_settings
    end

    test "create_user_settings/1 with valid data creates a user_settings", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id})
      assert {:ok, %UserSettings{} = user_settings} = Users.create_user_settings(attrs)

      assert user_settings.email_alert_on_new_message == true
    end

    test "create_user_settings/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_user_settings(@invalid_attrs)
    end

    test "create_or_update_settings/2 with valid data creates or updates the user_settings", %{
      user: user
    } do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id})

      assert {:ok, %UserSettings{} = user_settings} =
               Users.create_or_update_settings(user.id, attrs)

      assert user_settings.email_alert_on_new_message == true

      assert {:ok, %UserSettings{} = user_settings} =
               Users.create_or_update_settings(user.id, @update_attrs)

      assert user_settings.email_alert_on_new_message == false
    end
  end
end
