defmodule ChatApi.ReportingTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.Reporting

  setup do
    {:ok, account: insert(:account)}
  end

  describe "count_messages_by_date" do
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
  end

  describe "count_messages_per_user" do
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
  end

  describe "count_conversations_by_date" do
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
  end

  describe "count_sent_messages_by_date" do
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
  end

  describe "count_received_messages_by_date" do
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

  describe "average_seconds_to_first_reply" do
    test "gets the average seconds it takes to respond", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      first_replied_at = ~N[2020-09-01 12:30:00]

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        first_replied_at: first_replied_at
      )

      average_replied_time = Reporting.average_seconds_to_first_reply(account.id)
      assert average_replied_time == Time.diff(first_replied_at, inserted_at)
    end

    test "gets average response time of multiple times", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-09-01 12:00:00]
      first_replied_at_1 = ~N[2020-09-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-09-02 12:00:00]
      first_replied_at_2 = ~N[2020-09-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-09-01 10:00:00]
      first_replied_at_3 = ~N[2020-09-01 11:01:05]

      # 90000 seconds
      inserted_at_4 = ~N[2020-09-02 10:00:00]
      first_replied_at_4 = ~N[2020-09-03 11:00:00]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        first_replied_at: first_replied_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        first_replied_at: first_replied_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        first_replied_at: first_replied_at_3
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_4,
        first_replied_at: first_replied_at_4
      )

      average_replied_time = Reporting.average_seconds_to_first_reply(account.id)
      assert average_replied_time == (31 + 671 + 3665 + 90000) / 4
    end

    test "gets average response time of multiple times with filters", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-10-01 12:00:00]
      first_replied_at_1 = ~N[2020-10-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-10-02 12:00:00]
      first_replied_at_2 = ~N[2020-10-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-10-03 10:00:00]
      first_replied_at_3 = ~N[2020-10-03 11:01:05]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        first_replied_at: first_replied_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        first_replied_at: first_replied_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        first_replied_at: first_replied_at_3
      )

      average_replied_time =
        Reporting.average_seconds_to_first_reply(account.id, %{
          from_date: ~N[2020-10-01 11:00:00],
          to_date: ~N[2020-10-02 13:00:00]
        })

      assert average_replied_time == (31 + 671) / 2
    end

    test "when first_replied_at is nil", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      first_replied_at = nil

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        first_replied_at: first_replied_at
      )

      average_replied_time = Reporting.average_seconds_to_first_reply(account.id)
      assert average_replied_time == 0.0
    end
  end

  describe "median_seconds_to_first_reply" do
    test "gets the median seconds it takes to respond", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      first_replied_at = ~N[2020-09-01 12:30:00]

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        first_replied_at: first_replied_at
      )

      median_replied_time = Reporting.median_seconds_to_first_reply(account.id)
      assert median_replied_time == Time.diff(first_replied_at, inserted_at)
    end

    test "gets median response time of multiple times", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-09-01 12:00:00]
      first_replied_at_1 = ~N[2020-09-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-09-02 12:00:00]
      first_replied_at_2 = ~N[2020-09-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-09-01 10:00:00]
      first_replied_at_3 = ~N[2020-09-01 11:01:05]

      # 90000 seconds
      inserted_at_4 = ~N[2020-09-02 10:00:00]
      first_replied_at_4 = ~N[2020-09-03 11:00:00]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        first_replied_at: first_replied_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        first_replied_at: first_replied_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        first_replied_at: first_replied_at_3
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_4,
        first_replied_at: first_replied_at_4
      )

      median_replied_time = Reporting.median_seconds_to_first_reply(account.id)
      assert median_replied_time == (671 + 3665) / 2
    end

    test "gets median response time of multiple times with filters", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-10-01 12:00:00]
      first_replied_at_1 = ~N[2020-10-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-10-02 12:00:00]
      first_replied_at_2 = ~N[2020-10-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-10-03 10:00:00]
      first_replied_at_3 = ~N[2020-10-03 11:01:05]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        first_replied_at: first_replied_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        first_replied_at: first_replied_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        first_replied_at: first_replied_at_3
      )

      median_replied_time =
        Reporting.median_seconds_to_first_reply(account.id, %{
          from_date: ~N[2020-10-01 11:00:00],
          to_date: ~N[2020-10-02 13:00:00]
        })

      assert median_replied_time == (31 + 671) / 2
    end

    test "when first_replied_at is nil", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      first_replied_at = nil

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        first_replied_at: first_replied_at
      )

      assert 0 = Reporting.median_seconds_to_first_reply(account.id)
    end
  end

  describe "average_seconds_to_resolution" do
    test "gets the average seconds it takes to close", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      closed_at = ~N[2020-09-01 12:30:00]

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        closed_at: closed_at
      )

      average_resolution_time = Reporting.average_seconds_to_resolution(account.id)
      assert average_resolution_time == Time.diff(closed_at, inserted_at)
    end

    test "gets average resolution time of multiple times", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-09-01 12:00:00]
      closed_at_1 = ~N[2020-09-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-09-02 12:00:00]
      closed_at_2 = ~N[2020-09-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-09-01 10:00:00]
      closed_at_3 = ~N[2020-09-01 11:01:05]

      # 90000 seconds
      inserted_at_4 = ~N[2020-09-02 10:00:00]
      closed_at_4 = ~N[2020-09-03 11:00:00]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        closed_at: closed_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        closed_at: closed_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        closed_at: closed_at_3
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_4,
        closed_at: closed_at_4
      )

      average_resolution_time = Reporting.average_seconds_to_resolution(account.id)
      assert average_resolution_time == (31 + 671 + 3665 + 90000) / 4
    end

    test "gets average resolution time of multiple times with filters", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-10-01 12:00:00]
      closed_at_1 = ~N[2020-10-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-10-02 12:00:00]
      closed_at_2 = ~N[2020-10-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-10-03 10:00:00]
      closed_at_3 = ~N[2020-10-03 11:01:05]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        closed_at: closed_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        closed_at: closed_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        closed_at: closed_at_3
      )

      average_resolution_time =
        Reporting.average_seconds_to_resolution(account.id, %{
          from_date: ~N[2020-10-01 11:00:00],
          to_date: ~N[2020-10-02 13:00:00]
        })

      assert average_resolution_time == (31 + 671) / 2
    end

    test "when closed_at is nil", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      closed_at = nil

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        closed_at: closed_at
      )

      average_resolution_time = Reporting.average_seconds_to_resolution(account.id)
      assert average_resolution_time == 0.0
    end
  end

  describe "median_seconds_to_resolution" do
    test "gets the median seconds it takes to close", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      closed_at = ~N[2020-09-01 12:30:00]

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        closed_at: closed_at
      )

      median_resolution_time = Reporting.median_seconds_to_resolution(account.id)
      assert median_resolution_time == Time.diff(closed_at, inserted_at)
    end

    test "gets median resolution time of multiple times", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-09-01 12:00:00]
      closed_at_1 = ~N[2020-09-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-09-02 12:00:00]
      closed_at_2 = ~N[2020-09-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-09-01 10:00:00]
      closed_at_3 = ~N[2020-09-01 11:01:05]

      # 90000 seconds
      inserted_at_4 = ~N[2020-09-02 10:00:00]
      closed_at_4 = ~N[2020-09-03 11:00:00]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        closed_at: closed_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        closed_at: closed_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        closed_at: closed_at_3
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_4,
        closed_at: closed_at_4
      )

      median_resolution_time = Reporting.median_seconds_to_resolution(account.id)
      assert median_resolution_time == (671 + 3665) / 2
    end

    test "gets median resolution time of multiple times with filters", %{account: account} do
      # 31 seconds
      inserted_at_1 = ~N[2020-10-01 12:00:00]
      closed_at_1 = ~N[2020-10-01 12:00:31]

      # 671 seconds
      inserted_at_2 = ~N[2020-10-02 12:00:00]
      closed_at_2 = ~N[2020-10-02 12:11:11]

      # 3665 seconds
      inserted_at_3 = ~N[2020-10-03 10:00:00]
      closed_at_3 = ~N[2020-10-03 11:01:05]

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_1,
        closed_at: closed_at_1
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_2,
        closed_at: closed_at_2
      )

      insert(
        :conversation,
        account: account,
        inserted_at: inserted_at_3,
        closed_at: closed_at_3
      )

      median_resolution_time =
        Reporting.median_seconds_to_resolution(account.id, %{
          from_date: ~N[2020-10-01 11:00:00],
          to_date: ~N[2020-10-02 13:00:00]
        })

      assert median_resolution_time == (31 + 671) / 2
    end

    test "when closed_at is nil", %{
      account: account
    } do
      inserted_at = ~N[2020-09-01 12:00:00]
      closed_at = nil

      insert_list(
        3,
        :conversation,
        account: account,
        inserted_at: inserted_at,
        closed_at: closed_at
      )

      assert 0 = Reporting.median_seconds_to_resolution(account.id)
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

  describe "conversation_seconds_to_first_reply_by_date/2" do
    test "correctly calculates reply time metrics by date", %{account: account} do
      # 2020-09-28
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-09-28 10:00:00],
        first_replied_at: ~N[2020-09-28 11:02:03]
      )

      # 2020-10-02
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        first_replied_at: ~N[2020-10-02 12:00:20]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 11:00:00],
        first_replied_at: ~N[2020-10-02 11:05:30]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 10:00:00],
        first_replied_at: ~N[2020-10-02 10:02:20]
      )

      # 2020-10-03
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        first_replied_at: ~N[2020-10-03 12:00:05]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 11:00:00],
        first_replied_at: ~N[2020-10-03 11:10:15]
      )

      sorted =
        account.id
        |> Reporting.conversation_seconds_to_first_reply_by_date()
        |> Enum.map(fn record ->
          %{
            record
            | seconds_to_first_reply_list: Enum.sort(record.seconds_to_first_reply_list)
          }
        end)

      assert [
               %{
                 average: 3723.0,
                 date: ~D[2020-09-28],
                 median: 3723,
                 seconds_to_first_reply_list: [3723]
               },
               %{
                 average: 163.33333333333334,
                 date: ~D[2020-10-02],
                 median: 140,
                 seconds_to_first_reply_list: [20, 140, 330]
               },
               %{
                 average: 310.0,
                 date: ~D[2020-10-03],
                 median: 310.0,
                 seconds_to_first_reply_list: [5, 615]
               }
             ] = sorted
    end

    test "correctly calculates reply time metrics by date with filters", %{account: account} do
      # 2020-09-28
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-09-28 10:00:00],
        first_replied_at: ~N[2020-09-28 11:02:03]
      )

      # 2020-10-02
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        first_replied_at: ~N[2020-10-02 12:00:20]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 11:00:00],
        first_replied_at: ~N[2020-10-02 11:05:30]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 10:00:00],
        first_replied_at: ~N[2020-10-02 10:02:20]
      )

      # 2020-10-03
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        first_replied_at: ~N[2020-10-03 12:00:05]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 11:00:00],
        first_replied_at: ~N[2020-10-03 11:10:15]
      )

      sorted =
        account.id
        |> Reporting.conversation_seconds_to_first_reply_by_date(%{
          from_date: ~N[2020-10-01 12:00:00],
          to_date: ~N[2020-10-04 13:00:00]
        })
        |> Enum.map(fn record ->
          %{
            record
            | seconds_to_first_reply_list: Enum.sort(record.seconds_to_first_reply_list)
          }
        end)

      assert [
               %{
                 average: 163.33333333333334,
                 date: ~D[2020-10-02],
                 median: 140,
                 seconds_to_first_reply_list: [20, 140, 330]
               },
               %{
                 average: 310.0,
                 date: ~D[2020-10-03],
                 median: 310.0,
                 seconds_to_first_reply_list: [5, 615]
               }
             ] = sorted
    end

    test "correctly handles empty data", %{account: account} do
      assert [] =
               Reporting.conversation_seconds_to_first_reply_by_date(account.id, %{
                 from_date: ~N[2020-10-01 12:00:00],
                 to_date: ~N[2020-10-04 13:00:00]
               })
    end
  end

  describe "seconds_to_first_reply_metrics_by_week/2" do
    test "correctly calculates reply time metrics by date", %{account: account} do
      # 2020-09-28
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-09-28 10:00:00],
        first_replied_at: ~N[2020-09-28 11:02:03]
      )

      # 2020-10-02
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        first_replied_at: ~N[2020-10-02 12:00:20]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 11:00:00],
        first_replied_at: ~N[2020-10-02 11:05:30]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 10:00:00],
        first_replied_at: ~N[2020-10-02 10:02:20]
      )

      # 2020-10-03
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        first_replied_at: ~N[2020-10-03 12:00:05]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 11:00:00],
        first_replied_at: ~N[2020-10-03 11:10:15]
      )

      sorted =
        account.id
        |> Reporting.seconds_to_first_reply_metrics_by_week(%{
          from_date: ~N[2020-09-28 10:00:00],
          to_date: ~N[2020-10-04 13:00:00]
        })
        |> Enum.map(fn record ->
          %{
            record
            | seconds_to_first_reply_list: Enum.sort(record.seconds_to_first_reply_list)
          }
        end)

      assert [
               %{
                 average: 222.0,
                 end_date: ~D[2020-10-03],
                 median: 140,
                 seconds_to_first_reply_list: [5, 20, 140, 330, 615],
                 start_date: ~D[2020-09-27]
               }
             ] = sorted
    end

    test "correctly handles empty data", %{account: account} do
      assert [
               %{
                 average: 0.0,
                 end_date: ~D[2020-10-03],
                 median: 0,
                 seconds_to_first_reply_list: [],
                 start_date: ~D[2020-09-27]
               }
             ] =
               Reporting.seconds_to_first_reply_metrics_by_week(account.id, %{
                 from_date: ~N[2020-10-01 12:00:00],
                 to_date: ~N[2020-10-04 13:00:00]
               })
    end
  end

  describe "conversation_seconds_to_resolution_by_date/2" do
    test "correctly calculates resolution time metrics by date", %{account: account} do
      # 2020-09-28
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-09-28 10:00:00],
        closed_at: ~N[2020-09-28 11:02:03]
      )

      # 2020-10-02
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        closed_at: ~N[2020-10-02 12:00:20]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 11:00:00],
        closed_at: ~N[2020-10-02 11:05:30]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 10:00:00],
        closed_at: ~N[2020-10-02 10:02:20]
      )

      # 2020-10-03
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        closed_at: ~N[2020-10-03 12:00:05]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 11:00:00],
        closed_at: ~N[2020-10-03 11:10:15]
      )

      sorted =
        account.id
        |> Reporting.conversation_seconds_to_resolution_by_date()
        |> Enum.map(fn record ->
          %{
            record
            | seconds_to_resolution_list: Enum.sort(record.seconds_to_resolution_list)
          }
        end)

      assert [
               %{
                 average: 3723.0,
                 date: ~D[2020-09-28],
                 median: 3723,
                 seconds_to_resolution_list: [3723]
               },
               %{
                 average: 163.33333333333334,
                 date: ~D[2020-10-02],
                 median: 140,
                 seconds_to_resolution_list: [20, 140, 330]
               },
               %{
                 average: 310.0,
                 date: ~D[2020-10-03],
                 median: 310.0,
                 seconds_to_resolution_list: [5, 615]
               }
             ] = sorted
    end

    test "correctly calculates resolution time metrics by date with filters", %{account: account} do
      # 2020-09-28
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-09-28 10:00:00],
        closed_at: ~N[2020-09-28 11:02:03]
      )

      # 2020-10-02
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        closed_at: ~N[2020-10-02 12:00:20]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 11:00:00],
        closed_at: ~N[2020-10-02 11:05:30]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 10:00:00],
        closed_at: ~N[2020-10-02 10:02:20]
      )

      # 2020-10-03
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        closed_at: ~N[2020-10-03 12:00:05]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 11:00:00],
        closed_at: ~N[2020-10-03 11:10:15]
      )

      sorted =
        account.id
        |> Reporting.conversation_seconds_to_resolution_by_date(%{
          from_date: ~N[2020-10-01 12:00:00],
          to_date: ~N[2020-10-04 13:00:00]
        })
        |> Enum.map(fn record ->
          %{
            record
            | seconds_to_resolution_list: Enum.sort(record.seconds_to_resolution_list)
          }
        end)

      assert [
               %{
                 average: 163.33333333333334,
                 date: ~D[2020-10-02],
                 median: 140,
                 seconds_to_resolution_list: [20, 140, 330]
               },
               %{
                 average: 310.0,
                 date: ~D[2020-10-03],
                 median: 310.0,
                 seconds_to_resolution_list: [5, 615]
               }
             ] = sorted
    end

    test "correctly handles empty data", %{account: account} do
      assert [] =
               Reporting.conversation_seconds_to_resolution_by_date(account.id, %{
                 from_date: ~N[2020-10-01 12:00:00],
                 to_date: ~N[2020-10-04 13:00:00]
               })
    end
  end

  describe "seconds_to_resolution_metrics_by_week/2" do
    test "correctly calculates resolution time metrics by date", %{account: account} do
      # 2020-09-28
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-09-28 10:00:00],
        closed_at: ~N[2020-09-28 11:02:03]
      )

      # 2020-10-02
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 12:00:00],
        closed_at: ~N[2020-10-02 12:00:20]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 11:00:00],
        closed_at: ~N[2020-10-02 11:05:30]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-02 10:00:00],
        closed_at: ~N[2020-10-02 10:02:20]
      )

      # 2020-10-03
      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 12:00:00],
        closed_at: ~N[2020-10-03 12:00:05]
      )

      insert(:conversation,
        account: account,
        inserted_at: ~N[2020-10-03 11:00:00],
        closed_at: ~N[2020-10-03 11:10:15]
      )

      sorted =
        account.id
        |> Reporting.seconds_to_resolution_metrics_by_week(%{
          from_date: ~N[2020-09-28 10:00:00],
          to_date: ~N[2020-10-04 13:00:00]
        })
        |> Enum.map(fn record ->
          %{
            record
            | seconds_to_resolution_list: Enum.sort(record.seconds_to_resolution_list)
          }
        end)

      assert [
               %{
                 average: 222.0,
                 end_date: ~D[2020-10-03],
                 median: 140,
                 seconds_to_resolution_list: [5, 20, 140, 330, 615],
                 start_date: ~D[2020-09-27]
               }
             ] = sorted
    end

    test "correctly handles empty data", %{account: account} do
      assert [
               %{
                 average: 0.0,
                 end_date: ~D[2020-10-03],
                 median: 0,
                 seconds_to_resolution_list: [],
                 start_date: ~D[2020-09-27]
               }
             ] =
               Reporting.seconds_to_resolution_metrics_by_week(account.id, %{
                 from_date: ~N[2020-10-01 12:00:00],
                 to_date: ~N[2020-10-04 13:00:00]
               })
    end
  end

  describe "average" do
    test "returns zero for an empty list" do
      assert 0.0 = Reporting.average([])
    end

    test "correctly calculates the average" do
      assert 2.5 = Reporting.average([1, 2, 3, 4])
      assert 2.5 = Reporting.average([4, 3, 2, 1])
      assert 5.0 = Reporting.average([5, 5, 5])
      assert 0.5 = Reporting.average([-1, 2, -3, 4])
    end
  end

  describe "median" do
    test "returns zero for an empty list" do
      assert 0 = Reporting.median([])
    end

    test "correctly calculates the median" do
      assert 2.5 = Reporting.median([1, 2, 3, 4])
      assert 3 = Reporting.median([1, 2, 3, 4, 5])
      assert 3 = Reporting.median([3, 1, 2, 5, 4])
      assert 5 = Reporting.median([5, 5, 5])
      assert 0.5 = Reporting.median([-1, 2, -3, 4])
    end
  end

  describe "get_weekly_chunks/2" do
    test "gets the week tuples for the given date range" do
      from_date = ~N[2020-10-01 12:00:00]
      to_date = ~N[2020-10-04 13:00:00]

      assert [{~D[2020-09-27], ~D[2020-10-03]}] = Reporting.get_weekly_chunks(from_date, to_date)

      from_date = ~N[2020-10-01 12:00:00]
      to_date = ~N[2020-11-01 12:00:00]
      chunks = Reporting.get_weekly_chunks(from_date, to_date)

      assert [
               {~D[2020-10-25], ~D[2020-10-31]},
               {~D[2020-10-18], ~D[2020-10-24]},
               {~D[2020-10-11], ~D[2020-10-17]},
               {~D[2020-10-04], ~D[2020-10-10]},
               {~D[2020-09-27], ~D[2020-10-03]}
             ] = chunks

      # Verify that the start is on a Sunday (7) and the end is on a Saturday (6)
      assert Enum.all?(chunks, fn {start, _} -> Date.day_of_week(start) == 7 end)
      assert Enum.all?(chunks, fn {_, finish} -> Date.day_of_week(finish) == 6 end)
    end
  end
end
