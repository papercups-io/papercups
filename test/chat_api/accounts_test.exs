defmodule ChatApi.AccountsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.{Accounts, WidgetSettings, Users}

  describe "accounts" do
    alias ChatApi.Accounts.Account

    @valid_attrs %{company_name: "some company_name"}
    @update_attrs %{company_name: "some updated company_name"}
    @invalid_attrs %{company_name: nil}

    setup do
      {:ok, account: insert(:account)}
    end

    test "list_accounts/0 returns all accounts", %{account: account} do
      account_ids = Accounts.list_accounts() |> Enum.map(& &1.id)
      assert account_ids == [account.id]
    end

    test "get_account!/1 returns the account with given id",
         %{account: account} do
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

    test "update_account/2 with valid data updates the account",
         %{account: account} do
      assert {:ok, %Account{} = account} = Accounts.update_account(account, @update_attrs)
      assert account.company_name == "some updated company_name"
    end

    test "update_account/2 does not update billing information fields",
         %{account: account} do
      assert {:ok, %Account{} = account} =
               Accounts.update_account(account, %{subscription_plan: "team"})

      assert account.subscription_plan != "team"
    end

    test "update_account/2 updates the account's embedded settings",
         %{account: account} do
      assert {:ok, %Account{} = account} =
               Accounts.update_account(account, %{
                 settings: %{
                   disable_automated_reply_emails: true,
                   conversation_reminders_enabled: true,
                   conversation_reminder_hours_interval: 48
                 }
               })

      assert %Accounts.Settings{
               disable_automated_reply_emails: true,
               conversation_reminders_enabled: true,
               conversation_reminder_hours_interval: 48
             } = account.settings
    end

    test "update_account/2 with invalid data returns error changeset",
         %{account: account} do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)

      found_account = Accounts.get_account!(account.id)
      assert account.updated_at == found_account.updated_at
    end

    test "update_billing_info/2 updates billing information fields",
         %{account: account} do
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

    test "get_subscription_plan!/1 returns the account subscription plan",
         %{account: account} do
      assert "starter" = Accounts.get_subscription_plan!(account.id)

      assert {:ok, %Account{} = account} =
               Accounts.update_billing_info(account, %{subscription_plan: "team"})

      assert "team" = Accounts.get_subscription_plan!(account.id)
    end

    test "count_active_users/1 counts the number of active users on an account",
         %{account: account} do
      assert 0 = Accounts.count_active_users(account.id)

      user_1 = insert(:user, account: account)
      user_2 = insert(:user, account: account)
      _user_3 = insert(:user, account: account)

      assert 3 = Accounts.count_active_users(account.id)

      Users.disable_user(user_1)
      Users.archive_user(user_2)

      assert 1 = Accounts.count_active_users(account.id)
    end

    test "has_reached_user_capacity?/1 returns true for accounts on the 'starter' plan with >= 2 users",
         %{account: account} do
      assert "starter" = Accounts.get_subscription_plan!(account.id)
      refute Accounts.has_reached_user_capacity?(account.id)

      insert_list(3, :user, account: account)

      assert Accounts.has_reached_user_capacity?(account.id)
    end

    test "has_reached_user_capacity?/1 returns false for accounts on the 'team' plan with >= 2 users",
         %{account: account} do
      Accounts.update_billing_info(account, %{subscription_plan: "team"})
      refute Accounts.has_reached_user_capacity?(account.id)

      insert_list(3, :user, account: account)

      refute Accounts.has_reached_user_capacity?(account.id)
    end

    test "is_outside_working_hours?/2 returns false if no working hours are set",
         %{
           account: account
         } do
      refute Accounts.is_outside_working_hours?(account)
    end

    test "is_outside_working_hours?/2 returns false if working hours covers all day everyday",
         %{
           account: account
         } do
      {:ok, account} =
        Accounts.update_account(account, %{
          working_hours: [
            %{day: "everyday", start_minute: 0, end_minute: 1380}
          ]
        })

      refute Accounts.is_outside_working_hours?(account)
    end

    test "is_outside_working_hours?/2 returns true if day is not included in working hours",
         %{
           account: account
         } do
      {:ok, account} =
        Accounts.update_account(account, %{
          working_hours: [
            %{day: "monday", start_minute: 0, end_minute: 1380},
            %{day: "tuesday", start_minute: 0, end_minute: 1380}
          ]
        })

      sunday = ~U[2020-12-06 10:00:00Z]

      assert Accounts.is_outside_working_hours?(account, sunday)
    end

    test "is_outside_working_hours?/2 returns false if day is included in working hours",
         %{
           account: account
         } do
      {:ok, account} =
        Accounts.update_account(account, %{
          working_hours: [
            %{day: "monday", start_minute: 0, end_minute: 1380},
            %{day: "tuesday", start_minute: 0, end_minute: 1380}
          ]
        })

      tuesday = ~U[2020-12-08 10:00:00Z]

      refute Accounts.is_outside_working_hours?(account, tuesday)
    end

    test "is_outside_working_hours?/2 returns true if time is outside start_minute/end_minute",
         %{
           account: account
         } do
      {:ok, account} =
        Accounts.update_account(account, %{
          working_hours: [
            %{day: "everyday", start_minute: 0, end_minute: 30}
          ]
        })

      datetime = ~U[2020-12-08 10:40:00Z]

      assert Accounts.is_outside_working_hours?(account, datetime)
    end
  end
end
