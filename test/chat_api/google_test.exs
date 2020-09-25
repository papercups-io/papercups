defmodule ChatApi.GoogleTest do
  use ChatApi.DataCase

  alias ChatApi.Google

  describe "google_authorizations" do
    alias ChatApi.Google.GoogleAuthorization

    @valid_attrs %{client: "some client", refresh_token: "some long refresh token"}
    @update_attrs %{
      client: "some updated client",
      refresh_token: "some updated long refresh token"
    }
    @invalid_attrs %{client: nil}

    # TODO: move to text_fixture_helpers
    def google_authorization_fixture(attrs \\ %{}) do
      {:ok, google_authorization} =
        attrs
        |> Enum.into(create_valid_params())
        |> Google.create_google_authorization()

      google_authorization
    end

    def create_valid_params() do
      account = account_fixture()
      user = user_fixture(account)

      Map.merge(@valid_attrs, %{
        user_id: user.id,
        account_id: account.id
      })
    end

    test "list_google_authorizations/0 returns all google_authorizations" do
      google_authorization = google_authorization_fixture()
      assert Google.list_google_authorizations() == [google_authorization]
    end

    test "get_google_authorization!/1 returns the google_authorization with given id" do
      google_authorization = google_authorization_fixture()

      assert Google.get_google_authorization!(google_authorization.id) ==
               google_authorization
    end

    test "create_google_authorization/1 with valid data creates a google_authorization" do
      assert {:ok, %GoogleAuthorization{} = google_authorization} =
               Google.create_google_authorization(create_valid_params())

      assert google_authorization.client == "some client"
    end

    test "create_google_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Google.create_google_authorization(@invalid_attrs)
    end

    test "update_google_authorization/2 with valid data updates the google_authorization" do
      google_authorization = google_authorization_fixture()

      assert {:ok, %GoogleAuthorization{} = google_authorization} =
               Google.update_google_authorization(
                 google_authorization,
                 @update_attrs
               )

      assert google_authorization.client == "some updated client"
    end

    test "update_google_authorization/2 with invalid data returns error changeset" do
      google_authorization = google_authorization_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Google.update_google_authorization(
                 google_authorization,
                 @invalid_attrs
               )

      assert google_authorization ==
               Google.get_google_authorization!(google_authorization.id)
    end

    test "delete_google_authorization/1 deletes the google_authorization" do
      google_authorization = google_authorization_fixture()

      assert {:ok, %GoogleAuthorization{}} =
               Google.delete_google_authorization(google_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        Google.get_google_authorization!(google_authorization.id)
      end
    end

    test "change_google_authorization/1 returns a google_authorization changeset" do
      google_authorization = google_authorization_fixture()

      assert %Ecto.Changeset{} = Google.change_google_authorization(google_authorization)
    end
  end
end
