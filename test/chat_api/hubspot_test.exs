defmodule ChatApi.HubspotTest do
  use ChatApi.DataCase
  import ChatApi.Factory
  alias ChatApi.Hubspot

  describe "hubspot_authorizations" do
    alias ChatApi.Hubspot.HubspotAuthorization

    @valid_attrs %{
      access_token: "some access_token",
      refresh_token: "some refresh_token",
      metadata: %{},
      scope: "some scope",
      token_type: "some token_type"
    }
    @update_attrs %{
      access_token: "some updated access_token",
      refresh_token: "some updated refresh_token",
      metadata: %{},
      scope: "some updated scope",
      token_type: "some updated token_type"
    }
    @invalid_attrs %{
      access_token: nil,
      refresh_token: nil,
      scope: nil,
      token_type: nil,
      metadata: nil,
      account_id: nil,
      user_id: nil
    }

    setup do
      account = insert(:account)
      user = insert(:user, account: account, role: "admin")
      hubspot_authorization = insert(:hubspot_authorization, account: account, user: user)

      {:ok, account: account, user: user, hubspot_authorization: hubspot_authorization}
    end

    test "list_hubspot_authorizations/0 returns all hubspot_authorizations", %{
      hubspot_authorization: hubspot_authorization
    } do
      assert Hubspot.list_hubspot_authorizations() |> Enum.map(&extract_comparable_fields/1) == [
               extract_comparable_fields(hubspot_authorization)
             ]
    end

    test "get_hubspot_authorization!/1 returns the hubspot_authorization with given id", %{
      hubspot_authorization: hubspot_authorization
    } do
      result = Hubspot.get_hubspot_authorization!(hubspot_authorization.id)

      assert extract_comparable_fields(result) == extract_comparable_fields(hubspot_authorization)
    end

    test "create_hubspot_authorization/1 with valid data creates a hubspot_authorization", %{
      account: account,
      user: user
    } do
      params = Map.merge(@valid_attrs, %{user_id: user.id, account_id: account.id})

      assert {:ok, %HubspotAuthorization{} = hubspot_authorization} =
               Hubspot.create_hubspot_authorization(params)

      assert hubspot_authorization.access_token == "some access_token"
      assert hubspot_authorization.account_id == account.id
      assert hubspot_authorization.metadata == %{}
      assert hubspot_authorization.scope == "some scope"
      assert hubspot_authorization.token_type == "some token_type"
      assert hubspot_authorization.user_id == user.id
    end

    test "create_hubspot_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Hubspot.create_hubspot_authorization(@invalid_attrs)
    end

    test "update_hubspot_authorization/2 with valid data updates the hubspot_authorization", %{
      hubspot_authorization: hubspot_authorization
    } do
      assert {:ok, %HubspotAuthorization{} = hubspot_authorization} =
               Hubspot.update_hubspot_authorization(hubspot_authorization, @update_attrs)

      assert hubspot_authorization.access_token == "some updated access_token"
      assert hubspot_authorization.metadata == %{}
      assert hubspot_authorization.scope == "some updated scope"
      assert hubspot_authorization.token_type == "some updated token_type"
    end

    test "update_hubspot_authorization/2 with invalid data returns error changeset", %{
      hubspot_authorization: hubspot_authorization
    } do
      assert {:error, %Ecto.Changeset{}} =
               Hubspot.update_hubspot_authorization(hubspot_authorization, @invalid_attrs)

      current = Hubspot.get_hubspot_authorization!(hubspot_authorization.id)

      assert extract_comparable_fields(current) ==
               extract_comparable_fields(hubspot_authorization)
    end

    test "delete_hubspot_authorization/1 deletes the hubspot_authorization", %{
      hubspot_authorization: hubspot_authorization
    } do
      assert {:ok, %HubspotAuthorization{}} =
               Hubspot.delete_hubspot_authorization(hubspot_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        Hubspot.get_hubspot_authorization!(hubspot_authorization.id)
      end
    end

    test "change_hubspot_authorization/1 returns a hubspot_authorization changeset", %{
      hubspot_authorization: hubspot_authorization
    } do
      assert %Ecto.Changeset{} = Hubspot.change_hubspot_authorization(hubspot_authorization)
    end

    defp extract_comparable_fields(hubspot_authorization) do
      Map.take(hubspot_authorization, [:access_token, :scope, :token_type, :account_id, :user_id])
    end
  end
end
