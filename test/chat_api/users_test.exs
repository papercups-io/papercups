defmodule ChatApi.UsersTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, Users}
  alias ChatApi.Users.User

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
