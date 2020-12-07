defmodule ChatApi.GoogleTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.Google

  describe "google_authorizations" do
    alias ChatApi.Google.GoogleAuthorization

    @update_attrs %{
      client: "some updated client",
      refresh_token: "some updated long refresh token"
    }
    @invalid_attrs %{client: nil}

    setup do
      google_authorization = insert(:google_authorization)

      {:ok, google_authorization: google_authorization}
    end

    test "list_google_authorizations/0 returns all google_authorizations",
         %{google_authorization: google_authorization} do
      found_google_authorization_ids = Google.list_google_authorizations() |> Enum.map(& &1.id)

      assert found_google_authorization_ids == [google_authorization.id]
    end

    test "get_google_authorization!/1 returns the google_authorization with given id",
         %{google_authorization: google_authorization} do
      found_auth = Google.get_google_authorization!(google_authorization.id)

      assert found_auth.id == google_authorization.id
    end

    test "create_google_authorization/1 with valid data creates a google_authorization" do
      assert {:ok, %GoogleAuthorization{} = google_authorization} =
               Google.create_google_authorization(params_with_assocs(:google_authorization))

      assert google_authorization.client == "some client"
    end

    test "create_google_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Google.create_google_authorization(@invalid_attrs)
    end

    test "update_google_authorization/2 with valid data updates the google_authorization",
         %{google_authorization: google_authorization} do
      assert {:ok, %GoogleAuthorization{} = google_authorization} =
               Google.update_google_authorization(
                 google_authorization,
                 @update_attrs
               )

      assert google_authorization.client == "some updated client"
    end

    test "update_google_authorization/2 with invalid data returns error changeset",
         %{google_authorization: google_authorization} do
      assert {:error, %Ecto.Changeset{}} =
               Google.update_google_authorization(
                 google_authorization,
                 @invalid_attrs
               )
    end

    test "delete_google_authorization/1 deletes the google_authorization",
         %{google_authorization: google_authorization} do
      assert {:ok, %GoogleAuthorization{}} =
               Google.delete_google_authorization(google_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        Google.get_google_authorization!(google_authorization.id)
      end
    end

    test "change_google_authorization/1 returns a google_authorization changeset",
         %{google_authorization: google_authorization} do
      assert %Ecto.Changeset{} = Google.change_google_authorization(google_authorization)
    end
  end
end
