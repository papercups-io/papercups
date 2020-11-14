defmodule ChatApi.AccountsTest do
  import ChatApi.Factory
  use ChatApi.DataCase, async: true

  alias ChatApi.{Accounts, WidgetSettings}
  alias ChatApi.Accounts.Account

  describe "accounts" do
    @valid_attrs params_for(:account)
    @update_attrs params_for(:account, company_name: "updated company name")
    @invalid_attrs params_for(:account, company_name: "")

    test "list_accounts/0 returns all accounts" do
      insert_list(3, :account)

      all_accounts = Accounts.list_accounts()
      assert length(all_accounts) == 3
    end

    test "get_account!/1 returns the account with given id" do
      account = insert(:account)
      found_account = Accounts.get_account!(account.id)

      assert found_account.id === account.id
      assert found_account.company_name === account.company_name
    end

    test "create_account/1 with valid data creates a account and widget_setting" do
      assert {:ok, %Account{} = account} = Accounts.create_account(@valid_attrs)
      assert account.company_name != nil
      assert %WidgetSettings.WidgetSetting{} = WidgetSettings.get_settings_by_account(account.id)
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = insert(:account)

      assert {:ok, %Account{} = updated_account} = Accounts.update_account(account, @update_attrs)
      assert updated_account.company_name === @update_attrs.company_name
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = insert(:account)

      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)

      assert account |> Repo.preload([[users: :profile], :widget_settings]) ==
               Accounts.get_account!(account.id)
    end
  end
end
