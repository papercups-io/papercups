defmodule ChatApi.ApiKeysTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.ApiKeys

  describe "personal_api_keys" do
    alias ChatApi.ApiKeys.PersonalApiKey

    @update_attrs %{
      label: "some updated label",
      last_used_at: ~U[2010-05-18 14:00:00Z],
      value: "some updated value"
    }
    @invalid_attrs %{account_id: nil, label: nil, last_used_at: nil, user_id: nil, value: nil}

    setup do
      account = insert(:account)
      user = insert(:user, account: account)
      personal_api_key = insert(:personal_api_key, account: account, user: user)

      {:ok, account: account, user: user, personal_api_key: personal_api_key}
    end

    test "list_personal_api_keys/0 returns  all personal_api_keys",
         %{user: user, account: account, personal_api_key: personal_api_key} do
      personal_api_key_ids =
        ApiKeys.list_personal_api_keys(user.id, account.id)
        |> Enum.map(& &1.id)

      assert personal_api_key_ids == [personal_api_key.id]
    end

    test "get_personal_api_key!/1 returns the personal_api_key with given id",
         %{personal_api_key: personal_api_key} do
      assert Map.take(personal_api_key, [:id]) ==
               ApiKeys.get_personal_api_key!(personal_api_key.id)
               |> Map.take([:id])
    end

    test "create_personal_api_key/1 with valid data creates a personal_api_key",
         %{user: user, account: account} do
      attrs = params_for(:personal_api_key, account: account, user: user)

      assert {:ok, %PersonalApiKey{} = personal_api_key} = ApiKeys.create_personal_api_key(attrs)

      assert personal_api_key.user_id == user.id
      assert personal_api_key.account_id == account.id
    end

    test "create_personal_api_key/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ApiKeys.create_personal_api_key(@invalid_attrs)
    end

    test "update_personal_api_key/2 with valid data updates the personal_api_key",
         %{personal_api_key: personal_api_key} do
      assert {:ok, %PersonalApiKey{} = personal_api_key} =
               ApiKeys.update_personal_api_key(personal_api_key, @update_attrs)

      assert personal_api_key.label == "some updated label"
      assert personal_api_key.last_used_at == ~U[2010-05-18 14:00:00Z]
      assert personal_api_key.value == "some updated value"
    end

    test "update_personal_api_key/2 with invalid data returns error changeset",
         %{personal_api_key: personal_api_key} do
      assert {:error, %Ecto.Changeset{}} =
               ApiKeys.update_personal_api_key(personal_api_key, @invalid_attrs)
    end

    test "delete_personal_api_key/1 deletes the personal_api_key",
         %{personal_api_key: personal_api_key} do
      assert {:ok, %PersonalApiKey{}} = ApiKeys.delete_personal_api_key(personal_api_key)

      assert_raise Ecto.NoResultsError, fn ->
        ApiKeys.get_personal_api_key!(personal_api_key.id)
      end
    end

    test "change_personal_api_key/1 returns a personal_api_key changeset",
         %{personal_api_key: personal_api_key} do
      assert %Ecto.Changeset{} = ApiKeys.change_personal_api_key(personal_api_key)
    end
  end
end
