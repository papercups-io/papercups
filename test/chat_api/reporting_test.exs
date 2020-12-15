defmodule ChatApi.ReportingTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.Reporting

  describe "reporting" do
    setup do
      {:ok, account: insert(:account)}
    end

    test "count_messages_by_date/1 retrieves the number of messages created per day",
         %{account: account} do
      insert_list(
        10,
        :message,
        account: account,
        inserted_at: ~N[2020-09-01 12:00:00]
      )

      assert [%{count: 10, date: ~D[2020-09-01]}] = Reporting.count_messages_by_date(account.id)
    end

    test "count_messages_by_date/1 groups by date correctly",
         %{account: account} do
      insert_pair(:message, account: account, inserted_at: ~N[2020-09-01 12:00:00])
      insert(:message, account: account, inserted_at: ~N[2020-09-02 12:00:00])

      assert [
               %{date: ~D[2020-09-01], count: 2},
               %{date: ~D[2020-09-02], count: 1}
             ] = Reporting.count_messages_by_date(account.id)
    end

    test "count_messages_per_user/1 should return correct number of messages sent per user on team",
         %{account: account} do
      user_2 = insert(:user, account: account)
      user_3 = insert(:user, account: account)

      insert_pair(:message, account: account, user: user_2)
      insert(:message, account: account, user: user_3)

      assert [
               %{count: 2},
               %{count: 1}
             ] = Reporting.count_messages_per_user(account.id)
    end

    test "count_messages_by_date/1 only fetches messages by the given account id",
         %{account: account} do
      insert(:message, account: account, inserted_at: ~N[2020-09-01 12:00:00])

      assert [%{date: ~D[2020-09-01], count: 1}] = Reporting.count_messages_by_date(account.id)

      different_account = insert(:account)

      assert [] = Reporting.count_messages_by_date(different_account.id)
    end

    test "count_messages_by_date/3 fetches conversations between two dates",
         %{account: account} do
      insert_pair(
        :message,
        account: account,
        inserted_at: ~N[2020-09-02 12:00:00]
      )

      insert(:message, account: account, inserted_at: ~N[2020-09-03 12:00:00])

      assert [
               %{date: ~D[2020-09-02], count: 2},
               %{date: ~D[2020-09-03], count: 1}
             ] =
               Reporting.count_messages_by_date(
                 account.id,
                 ~N[2020-09-02 11:00:00],
                 ~N[2020-09-03 13:00:00]
               )
    end

    test "count_conversations_by_date/1 retrieves the number of conversations created per day",
         %{account: account} do
      insert_list(
        5,
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-01 12:00:00]
      )

      assert [%{count: 5, date: ~D[2020-09-01]}] =
               Reporting.count_conversations_by_date(account.id)
    end

    test "count_conversations_by_date/1 groups by date correctly",
         %{account: account} do
      insert_pair(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-01 12:00:00]
      )

      insert(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-02 12:00:00]
      )

      assert [
               %{date: ~D[2020-09-01], count: 2},
               %{date: ~D[2020-09-02], count: 1}
             ] = Reporting.count_conversations_by_date(account.id)
    end

    test "count_conversations_by_date/3 fetches conversations between two dates",
         %{account: account} do
      insert(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-01 12:00:00]
      )

      insert_pair(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-02 12:00:00]
      )

      insert(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-03 12:00:00]
      )

      insert(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-04 12:00:00]
      )

      insert(
        :conversation,
        account: account,
        inserted_at: ~N[2020-09-05 12:00:00]
      )

      assert [
               %{date: ~D[2020-09-02], count: 2},
               %{date: ~D[2020-09-03], count: 1}
             ] =
               Reporting.count_conversations_by_date(
                 account.id,
                 ~N[2020-09-02 11:00:00],
                 ~N[2020-09-03 13:00:00]
               )
    end

    test "count_sent_messages_by_date/1 groups by date correctly",
         %{account: account} do
      user_2 = insert(:user, account: account)
      user_3 = insert(:user, account: account)

      insert(
        :message,
        account: account,
        inserted_at: ~N[2020-09-01 12:00:00],
        user: user_2
      )

      insert(
        :message,
        account: account,
        inserted_at: ~N[2020-09-02 12:00:00],
        user: user_3
      )

      # Same date different users
      insert(
        :message,
        account: account,
        inserted_at: ~N[2020-09-03 12:00:00],
        user: user_2
      )

      insert(
        :message,
        account: account,
        inserted_at: ~N[2020-09-03 12:00:00],
        user: user_3
      )

      # Same date from Customer (shall be ignored)
      insert(
        :message,
        account: account,
        inserted_at: ~N[2020-09-03 12:00:00],
        user: nil
      )

      assert [
               %{date: ~D[2020-09-01], count: 1},
               %{date: ~D[2020-09-02], count: 1},
               %{date: ~D[2020-09-03], count: 2}
             ] = Reporting.count_sent_messages_by_date(account.id)
    end

    test "count_received_messages_by_date/1 groups by date correctly",
         %{account: account} do
      # Messages from Customer (not user)
      insert(:message,
        account: account,
        inserted_at: ~N[2020-09-01 12:00:00],
        user: nil
      )

      insert_pair(:message,
        account: account,
        inserted_at: ~N[2020-09-02 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-09-03 12:00:00],
        user: nil
      )

      # Messages from User (not customer)
      insert_list(3, :message,
        account: account,
        inserted_at: ~N[2020-09-03 12:00:00],
        customer: nil
      )

      assert [
               %{date: ~D[2020-09-01], count: 1},
               %{date: ~D[2020-09-02], count: 2},
               %{date: ~D[2020-09-03], count: 1}
             ] = Reporting.count_received_messages_by_date(account.id)
    end
  end

  describe "get_customer_breakdown/1" do
    setup do
      account = insert(:account)

      insert(:customer,
        account: account,
        inserted_at: ~N[2020-10-12 12:00:00],
        browser: "Chrome",
        time_zone: "UTC",
        os: "Windows"
      )

      insert(:customer,
        account: account,
        inserted_at: ~N[2020-10-11 12:00:00],
        browser: "Chrome",
        time_zone: "UTC-1",
        os: "Linux"
      )

      insert(:customer,
        account: account,
        inserted_at: ~N[2020-10-12 12:00:00],
        browser: "Firefox",
        time_zone: "UTC-1",
        os: "MacOS"
      )

      insert(:customer,
        account: account,
        inserted_at: ~N[2020-10-12 12:00:00],
        browser: "Safari",
        time_zone: "UTC-10",
        os: "MacOS"
      )

      {:ok, account: account}
    end

    test "it groups by field correctly", %{account: account} do
      assert [
               %{browser: "Chrome", count: 2},
               %{browser: "Firefox", count: 1},
               %{browser: "Safari", count: 1}
             ] =
               Reporting.get_customer_breakdown(account.id, :browser, %{
                 from_date: ~N[2020-10-11 11:00:00],
                 to_date: ~N[2020-10-12 13:00:00]
               })
               |> Enum.sort_by(& &1.browser, :asc)
    end

    test "it slices time correctly", %{account: account} do
      assert [
               %{browser: "Chrome", count: 1},
               %{browser: "Firefox", count: 1},
               %{browser: "Safari", count: 1}
             ] =
               Reporting.get_customer_breakdown(account.id, :browser, %{
                 from_date: ~N[2020-10-11 12:00:00],
                 to_date: ~N[2020-10-12 13:00:00]
               })
               |> Enum.sort_by(& &1.browser, :asc)
    end

    test "it can query by other fields", %{account: account} do
      assert [
               %{os: "MacOS", count: 2},
               %{os: "Linux", count: 1},
               %{os: "Windows", count: 1}
             ] =
               Reporting.get_customer_breakdown(account.id, :os, %{
                 from_date: ~N[2020-10-10 12:00:00],
                 to_date: ~N[2020-10-12 13:00:00]
               })
    end
  end

  describe "count_messages_by_weekday/1" do
    setup do
      account = insert(:account)

      {:ok, account: account}
    end

    test "correctly calculates total and avg of customer messages per day",
         %{account: account} do
      insert(:message,
        account: account,
        inserted_at: ~N[2020-09-28 12:00:00],
        user: nil
      )

      insert_pair(:message,
        account: account,
        inserted_at: ~N[2020-09-29 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-09-30 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-10-01 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-10-04 12:00:00],
        user: nil
      )

      insert(:message,
        account: account,
        inserted_at: ~N[2020-10-05 15:00:00],
        user: nil
      )

      assert [
               %{day: "Monday", average: 1.0, total: 2},
               %{day: "Tuesday", average: 2.0, total: 2},
               %{day: "Wednesday", average: 1.0, total: 1},
               %{day: "Thursday", average: 1.0, total: 1},
               %{day: "Friday", average: 1.0, total: 1},
               %{day: "Saturday", average: 1.0, total: 1},
               %{day: "Sunday", average: 1.0, total: 1}
             ] = Reporting.count_messages_by_weekday(account.id)
    end

    test "includes zero day counts for weekdays with no messages",
         %{account: account} do
      insert(:message, account: account, inserted_at: ~N[2020-09-28 12:00:00])

      assert [
               %{day: "Monday", average: 1.0, total: 1},
               %{day: "Tuesday", average: 0.0, total: 0},
               %{day: "Wednesday", average: 0.0, total: 0},
               %{day: "Thursday", average: 0.0, total: 0},
               %{day: "Friday", average: 0.0, total: 0},
               %{day: "Saturday", average: 0.0, total: 0},
               %{day: "Sunday", average: 0.0, total: 0}
             ] = Reporting.count_messages_by_weekday(account.id)
    end

    test "doesn't count messages without a customer", %{account: account} do
      insert(:message, account: account, customer: nil, inserted_at: ~N[2020-09-28 12:00:00])

      assert [
               %{day: "Monday", average: 0.0, total: 0},
               %{day: "Tuesday", average: 0.0, total: 0},
               %{day: "Wednesday", average: 0.0, total: 0},
               %{day: "Thursday", average: 0.0, total: 0},
               %{day: "Friday", average: 0.0, total: 0},
               %{day: "Saturday", average: 0.0, total: 0},
               %{day: "Sunday", average: 0.0, total: 0}
             ] = Reporting.count_messages_by_weekday(account.id)
    end

    test "doesn't count messages from other accounts", %{account: account} do
      different_account = insert(:account)
      insert(:message, account: different_account, inserted_at: ~N[2020-09-28 12:00:00])

      assert [
               %{day: "Monday", average: 0.0, total: 0},
               %{day: "Tuesday", average: 0.0, total: 0},
               %{day: "Wednesday", average: 0.0, total: 0},
               %{day: "Thursday", average: 0.0, total: 0},
               %{day: "Friday", average: 0.0, total: 0},
               %{day: "Saturday", average: 0.0, total: 0},
               %{day: "Sunday", average: 0.0, total: 0}
             ] = Reporting.count_messages_by_weekday(account.id)
    end
  end

  describe "count_customers_by_date/1" do
    setup do
      account = insert(:account)

      {:ok, account: account}
    end

    test "it groups by date correctly", %{account: account} do
      insert(:customer, account: account, inserted_at: ~N[2020-10-10 12:00:00])
      insert(:customer, account: account, inserted_at: ~N[2020-10-11 12:00:00])
      insert_pair(:customer, account: account, inserted_at: ~N[2020-10-12 12:00:00])

      assert [
               %{date: ~D[2020-10-10], count: 1},
               %{date: ~D[2020-10-11], count: 1},
               %{date: ~D[2020-10-12], count: 2}
             ] = Reporting.count_customers_by_date(account.id)
    end
  end

  describe "count_customers_by_date/3" do
    setup do
      account = insert(:account)

      {:ok, account: account}
    end

    test "Fetches customers between two dates", %{account: account} do
      insert(:customer, account: account, inserted_at: ~N[2020-10-12 12:00:00])
      insert(:customer, account: account, inserted_at: ~N[2020-10-11 12:00:00])
      insert(:customer, account: account, inserted_at: ~N[2020-10-10 12:00:00])
      insert(:customer, account: account, inserted_at: ~N[2020-10-13 12:00:00])

      assert [
               %{date: ~D[2020-10-10], count: 1},
               %{date: ~D[2020-10-11], count: 1},
               %{date: ~D[2020-10-12], count: 1}
             ] =
               Reporting.count_customers_by_date(
                 account.id,
                 ~N[2020-10-10 11:00:00],
                 ~N[2020-10-12 13:00:00]
               )
    end
  end
end
