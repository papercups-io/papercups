defmodule ChatApi.AccountsTest do
  use ChatApi.DataCase, async: true

  alias ChatApi.{Accounts, WidgetSettings, Users}

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

    test "create_account/1 with valid data creates an account and widget_setting" do
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

    test "change_account/1 returns an account changeset", %{account: account} do
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end

    test "get_subscription_plan!/1 returns the account subscription plan", %{account: account} do
      assert "starter" = Accounts.get_subscription_plan!(account.id)

      assert {:ok, %Account{} = account} =
               Accounts.update_billing_info(account, %{subscription_plan: "team"})

      assert "team" = Accounts.get_subscription_plan!(account.id)
    end

    test "count_active_users/1 counts the number of active users on an account", %{
      account: account
    } do
      assert 0 = Accounts.count_active_users(account.id)

      user_1 = user_fixture(account)
      user_2 = user_fixture(account)
      _user_3 = user_fixture(account)

      assert 3 = Accounts.count_active_users(account.id)

      Users.disable_user(user_1)
      Users.archive_user(user_2)

      assert 1 = Accounts.count_active_users(account.id)
    end

    test "has_reached_user_capacity?/1 returns true for accounts on the 'starter' plan with >= 2 users",
         %{
           account: account
         } do
      assert "starter" = Accounts.get_subscription_plan!(account.id)
      refute Accounts.has_reached_user_capacity?(account.id)

      for _n <- 1..3 do
        user_fixture(account)
      end

      assert Accounts.has_reached_user_capacity?(account.id)
    end

    test "has_reached_user_capacity?/1 returns false for accounts on the 'team' plan with >= 2 users",
         %{
           account: account
         } do
      Accounts.update_billing_info(account, %{subscription_plan: "team"})
      refute Accounts.has_reached_user_capacity?(account.id)

      for _n <- 1..3 do
        user_fixture(account)
      end

      refute Accounts.has_reached_user_capacity?(account.id)
    end
  end
end
