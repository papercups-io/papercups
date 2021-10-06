defmodule ChatApi.IntercomTest do
  use ChatApi.DataCase
  import ChatApi.Factory
  alias ChatApi.Intercom

  describe "intercom_authorizations" do
    alias ChatApi.Intercom.IntercomAuthorization

    @valid_attrs %{
      access_token: "some access_token",
      metadata: %{},
      scope: "some scope",
      token_type: "some token_type"
    }
    @update_attrs %{
      access_token: "some updated access_token",
      metadata: %{},
      scope: "some updated scope",
      token_type: "some updated token_type"
    }
    @invalid_attrs %{
      access_token: nil,
      scope: nil,
      token_type: nil,
      metadata: nil,
      account_id: nil,
      user_id: nil
    }

    setup do
      account = insert(:account)
      user = insert(:user, account: account, role: "admin")
      intercom_authorization = insert(:intercom_authorization, account: account, user: user)

      {:ok, account: account, user: user, intercom_authorization: intercom_authorization}
    end

    test "list_intercom_authorizations/0 returns all intercom_authorizations", %{
      intercom_authorization: intercom_authorization
    } do
      assert Intercom.list_intercom_authorizations() |> Enum.map(&extract_comparable_fields/1) ==
               [
                 extract_comparable_fields(intercom_authorization)
               ]
    end

    test "get_intercom_authorization!/1 returns the intercom_authorization with given id", %{
      intercom_authorization: intercom_authorization
    } do
      result = Intercom.get_intercom_authorization!(intercom_authorization.id)

      assert extract_comparable_fields(result) ==
               extract_comparable_fields(intercom_authorization)
    end

    test "create_intercom_authorization/1 with valid data creates a intercom_authorization", %{
      account: account,
      user: user
    } do
      params = Map.merge(@valid_attrs, %{user_id: user.id, account_id: account.id})

      assert {:ok, %IntercomAuthorization{} = intercom_authorization} =
               Intercom.create_intercom_authorization(params)

      assert intercom_authorization.access_token == "some access_token"
      assert intercom_authorization.account_id == account.id
      assert intercom_authorization.metadata == %{}
      assert intercom_authorization.scope == "some scope"
      assert intercom_authorization.token_type == "some token_type"
      assert intercom_authorization.user_id == user.id
    end

    test "create_intercom_authorization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Intercom.create_intercom_authorization(@invalid_attrs)
    end

    test "update_intercom_authorization/2 with valid data updates the intercom_authorization", %{
      intercom_authorization: intercom_authorization
    } do
      assert {:ok, %IntercomAuthorization{} = intercom_authorization} =
               Intercom.update_intercom_authorization(intercom_authorization, @update_attrs)

      assert intercom_authorization.access_token == "some updated access_token"
      assert intercom_authorization.metadata == %{}
      assert intercom_authorization.scope == "some updated scope"
      assert intercom_authorization.token_type == "some updated token_type"
    end

    test "update_intercom_authorization/2 with invalid data returns error changeset", %{
      intercom_authorization: intercom_authorization
    } do
      assert {:error, %Ecto.Changeset{}} =
               Intercom.update_intercom_authorization(intercom_authorization, @invalid_attrs)

      current = Intercom.get_intercom_authorization!(intercom_authorization.id)

      assert extract_comparable_fields(current) ==
               extract_comparable_fields(intercom_authorization)
    end

    test "delete_intercom_authorization/1 deletes the intercom_authorization", %{
      intercom_authorization: intercom_authorization
    } do
      assert {:ok, %IntercomAuthorization{}} =
               Intercom.delete_intercom_authorization(intercom_authorization)

      assert_raise Ecto.NoResultsError, fn ->
        Intercom.get_intercom_authorization!(intercom_authorization.id)
      end
    end

    test "change_intercom_authorization/1 returns a intercom_authorization changeset", %{
      intercom_authorization: intercom_authorization
    } do
      assert %Ecto.Changeset{} = Intercom.change_intercom_authorization(intercom_authorization)
    end

    defp extract_comparable_fields(intercom_authorization) do
      Map.take(intercom_authorization, [:access_token, :scope, :token_type, :account_id, :user_id])
    end
  end
end
