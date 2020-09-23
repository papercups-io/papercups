defmodule ChatApi.GoogleAuthorizationsTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, GoogleAuthorizations, Users.User}

  describe "google_authorizations" do
    alias ChatApi.GoogleAuthorizations.GoogleAuthorization

    @valid_attrs %{client: "some client", refresh_token: "some long refresh token"}
    @update_attrs %{
      client: "some updated client",
      refresh_token: "some updated long refresh token"
    }
    @invalid_attrs %{client: nil}
    @password "supersecretpassword"

    def account_fixture(_attrs \\ %{}) do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      account
    end

    def user_fixture(_attrs \\ %{}) do
      account = account_fixture()

      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        password: @password,
        password_confirmation: @password,
        account_id: account.id
      })
      |> Repo.insert!()
    end

    def google_authorization_fixture(attrs \\ %{}) do
      {:ok, google_authorization} =
        attrs
        |> Enum.into(create_valid_params())
        |> GoogleAuthorizations.create_google_authorization()

      google_authorization
    end

    def create_valid_params() do
      user = user_fixture()

      Map.merge(@valid_attrs, %{
        user_id: user.id,
        account_id: user.account_id
      })
    end

    test "list_google_authorizations/0 returns all google_authorizations" do
      google_authorization = google_authorization_fixture()
      assert GoogleAuthorizations.list_google_authorizations() == [google_authorization]
    end

    test "get_google_authorization!/1 returns the google_authorization with given id" do
      google_authorization = google_authorization_fixture()

      assert GoogleAuthorizations.get_google_authorization!(google_authorization.id) ==
               google_authorization
    end

    test "create_google_authorization/1 with valid data creates a google_authorization" do
      assert {:ok, %GoogleAuthorization{} = google_authorization} =
               GoogleAuthorizations.create_google_authorization(create_valid_params())

      assert google_authorization.client == "some client"
    end

    test "create_google_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               GoogleAuthorizations.create_google_authorization(@invalid_attrs)
    end

    test "update_google_authorization/2 with valid data updates the google_authorization" do
      google_authorization = google_authorization_fixture()

      assert {:ok, %GoogleAuthorization{} = google_authorization} =
               GoogleAuthorizations.update_google_authorization(
                 google_authorization,
                 @update_attrs
               )

      assert google_authorization.client == "some updated client"
    end

    test "update_google_authorization/2 with invalid data returns error changeset" do
      google_authorization = google_authorization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               GoogleAuthorizations.update_google_authorization(
                 google_authorization,
                 @invalid_attrs
               )

      assert google_authorization ==
               GoogleAuthorizations.get_google_authorization!(google_authorization.id)
    end

    test "delete_google_authorization/1 deletes the google_authorization" do
      google_authorization = google_authorization_fixture()

      assert {:ok, %GoogleAuthorization{}} =
               GoogleAuthorizations.delete_google_authorization(google_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        GoogleAuthorizations.get_google_authorization!(google_authorization.id)
      end
    end

    test "change_google_authorization/1 returns a google_authorization changeset" do
      google_authorization = google_authorization_fixture()

      assert %Ecto.Changeset{} =
               GoogleAuthorizations.change_google_authorization(google_authorization)
    end
  end
end
