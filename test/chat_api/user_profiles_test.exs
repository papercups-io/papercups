defmodule ChatApi.UserProfilesTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, UserProfiles}
  alias ChatApi.Users.User

  describe "profiles" do
    alias ChatApi.UserProfiles.UserProfile

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
        |> UserProfiles.create_user_profile()

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

    test "get_user_profile/1 returns the user_profile with given id", %{user: user} do
      user_profile = user_profile_fixture(%{user_id: user.id})

      assert UserProfiles.get_user_profile(user.id) == user_profile
    end

    test "create_user_profile/1 with valid data creates a user_profile", %{user: user} do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id})
      assert {:ok, %UserProfile{} = user_profile} = UserProfiles.create_user_profile(attrs)

      assert user_profile.display_name == "some display_name"
      assert user_profile.full_name == "some full_name"
      assert user_profile.profile_photo_url == "some profile_photo_url"
    end

    test "create_user_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserProfiles.create_user_profile(@invalid_attrs)
    end

    test "create_or_update_profile/2 with valid data creates or updates the user_profile", %{
      user: user
    } do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id})

      assert {:ok, %UserProfile{} = user_profile} =
               UserProfiles.create_or_update_profile(user.id, attrs)

      assert user_profile.display_name == "some display_name"

      assert {:ok, %UserProfile{} = user_profile} =
               UserProfiles.create_or_update_profile(user.id, @update_attrs)

      assert user_profile.display_name == "some updated display_name"
    end
  end
end
