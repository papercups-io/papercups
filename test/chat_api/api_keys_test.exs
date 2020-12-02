defmodule ChatApi.ApiKeysTest do
  use ChatApi.DataCase

  alias ChatApi.ApiKeys

  describe "personal_api_keys" do
    alias ChatApi.ApiKeys.PersonalApiKey

    @valid_attrs %{
      label: "some label",
      last_used_at: ~U[2010-04-17 14:00:00Z],
      value: "some value"
    }
    @update_attrs %{
      label: "some updated label",
      last_used_at: ~U[2010-05-18 14:00:00Z],
      value: "some updated value"
    }
    @invalid_attrs %{account_id: nil, label: nil, last_used_at: nil, user_id: nil, value: nil}

    setup do
      account = account_fixture()
      user = user_fixture(account)

      {:ok, account: account, user: user}
    end

    test "list_personal_api_keys/0 returns all personal_api_keys", %{user: user, account: account} do
      personal_api_key = personal_api_key_fixture(user)

      assert ApiKeys.list_personal_api_keys(user.id, account.id) == [personal_api_key]
    end

    test "get_personal_api_key!/1 returns the personal_api_key with given id", %{user: user} do
      personal_api_key = personal_api_key_fixture(user)
      assert ApiKeys.get_personal_api_key!(personal_api_key.id) == personal_api_key
    end

    test "create_personal_api_key/1 with valid data creates a personal_api_key", %{
      user: user,
      account: account
    } do
      attrs = Map.merge(@valid_attrs, %{user_id: user.id, account_id: account.id})
      assert {:ok, %PersonalApiKey{} = personal_api_key} = ApiKeys.create_personal_api_key(attrs)

      assert personal_api_key.user_id == user.id
      assert personal_api_key.account_id == account.id
      assert personal_api_key.label == "some label"
      assert personal_api_key.last_used_at == ~U[2010-04-17 14:00:00Z]
      assert personal_api_key.value == "some value"
    end

    test "create_personal_api_key/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ApiKeys.create_personal_api_key(@invalid_attrs)
    end

    test "update_personal_api_key/2 with valid data updates the personal_api_key", %{user: user} do
      personal_api_key = personal_api_key_fixture(user)

      assert {:ok, %PersonalApiKey{} = personal_api_key} =
               ApiKeys.update_personal_api_key(personal_api_key, @update_attrs)

      assert personal_api_key.label == "some updated label"
      assert personal_api_key.last_used_at == ~U[2010-05-18 14:00:00Z]
      assert personal_api_key.value == "some updated value"
    end

    test "update_personal_api_key/2 with invalid data returns error changeset", %{user: user} do
      personal_api_key = personal_api_key_fixture(user)

      assert {:error, %Ecto.Changeset{}} =
               ApiKeys.update_personal_api_key(personal_api_key, @invalid_attrs)

      assert personal_api_key == ApiKeys.get_personal_api_key!(personal_api_key.id)
    end

    test "delete_personal_api_key/1 deletes the personal_api_key", %{user: user} do
      personal_api_key = personal_api_key_fixture(user)
      assert {:ok, %PersonalApiKey{}} = ApiKeys.delete_personal_api_key(personal_api_key)

      assert_raise Ecto.NoResultsError, fn ->
        ApiKeys.get_personal_api_key!(personal_api_key.id)
      end
    end

    test "change_personal_api_key/1 returns a personal_api_key changeset", %{user: user} do
      personal_api_key = personal_api_key_fixture(user)
      assert %Ecto.Changeset{} = ApiKeys.change_personal_api_key(personal_api_key)
    end
  end
end
