defmodule ChatApi.AccountsTest do
  use ChatApi.DataCase, async: true

  alias ChatApi.{Accounts, WidgetSettings}

  describe "accounts" do
    alias ChatApi.Accounts.Account

    @valid_attrs %{company_name: "some company_name"}
    @update_attrs %{company_name: "some updated company_name"}
    @invalid_attrs %{company_name: nil}

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_accounts/0 returns all accounts", %{account: account} do
      ids = Accounts.list_accounts() |> Enum.map(& &1.id)
      assert ids == [account.id]
    end

    test "get_account!/1 returns the account with given id", %{account: account} do
      assert Accounts.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account and widget_setting" do
      assert {:ok, %Account{} = account} = Accounts.create_account(@valid_attrs)
      assert account.company_name == "some company_name"

      assert %WidgetSettings.WidgetSetting{} = WidgetSettings.get_settings_by_account(account.id)
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account", %{account: account} do
      assert {:ok, %Account{} = account} = Accounts.update_account(account, @update_attrs)
      assert account.company_name == "some updated company_name"
    end

    test "update_account/2 does not update billing information fields", %{account: account} do
      assert {:ok, %Account{} = account} =
               Accounts.update_account(account, %{subscription_plan: "team"})

      assert account.subscription_plan != "team"
    end

    test "update_account/2 with invalid data returns error changeset", %{account: account} do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id)
    end

    test "update_billing_info/2 updates billing information fields", %{account: account} do
      assert {:ok, %Account{} = account} =
               Accounts.update_billing_info(account, %{subscription_plan: "team"})

      assert account.subscription_plan == "team"
    end

    test "delete_account/1 deletes the account", %{account: account} do
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset", %{account: account} do
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end
end
