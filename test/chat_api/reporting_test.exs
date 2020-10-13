defmodule ChatApi.ReportingTest do
  use ChatApi.DataCase

  alias ChatApi.Reporting

  describe "reporting" do
    setup do
      account = account_fixture()
      customer = customer_fixture(account)

      {:ok, account: account, customer: customer}
    end

    test "count_messages_by_date/1 retrieves the number of messages created per day", %{
      account: account,
      customer: customer
    } do
      count = 10
      inserted_at = ~N[2020-09-01 12:00:00]
      conversation = conversation_fixture(account, customer)

      for _i <- 1..count do
        message_fixture(account, conversation, %{inserted_at: inserted_at})
      end

      assert [%{count: ^count, date: ~D[2020-09-01]}] =
               Reporting.count_messages_by_date(account.id)
    end

    test "count_messages_by_date/1 groups by date correctly", %{
      account: account,
      customer: customer
    } do
      conversation = conversation_fixture(account, customer)
      message_fixture(account, conversation, %{inserted_at: ~N[2020-09-01 12:00:00]})
      message_fixture(account, conversation, %{inserted_at: ~N[2020-09-02 12:00:00]})
      message_fixture(account, conversation, %{inserted_at: ~N[2020-09-03 12:00:00]})

      assert [
               %{date: ~D[2020-09-01], count: 1},
               %{date: ~D[2020-09-02], count: 1},
               %{date: ~D[2020-09-03], count: 1}
             ] = Reporting.count_messages_by_date(account.id)
    end

    test "count_messages_per_user/1 should return correct number of messages sent per user on team",
         %{
           account: account,
           customer: customer
         } do
      user_2 = user_fixture(account)
      user_3 = user_fixture(account)
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-01 12:00:00],
        user_id: user_2.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-02 12:00:00],
        user_id: user_2.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        user_id: user_3.id
      })

      assert [
               %{count: 2},
               %{count: 1}
             ] = Reporting.count_messages_per_user(account.id)
    end

    test "count_messages_by_date/1 only fetches messages by the given account id", %{
      account: account,
      customer: customer
    } do
      conversation = conversation_fixture(account, customer)
      message_fixture(account, conversation, %{inserted_at: ~N[2020-09-01 12:00:00]})

      assert [%{date: ~D[2020-09-01], count: 1}] = Reporting.count_messages_by_date(account.id)

      different_account = account_fixture()

      assert [] = Reporting.count_messages_by_date(different_account.id)
    end

    test "count_messages_by_date/3 fetches conversations between two dates", %{
      account: account,
      customer: customer
    } do
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-02 12:00:00]
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-02 12:00:00]
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00]
      })

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

    test "count_conversations_by_date/1 retrieves the number of conversations created per day", %{
      account: account,
      customer: customer
    } do
      count = 5
      inserted_at = ~N[2020-09-01 12:00:00]

      for _i <- 1..count do
        conversation_fixture(account, customer, %{inserted_at: inserted_at})
      end

      assert [%{count: ^count, date: ~D[2020-09-01]}] =
               Reporting.count_conversations_by_date(account.id)
    end

    test "count_conversations_by_date/1 groups by date correctly", %{
      account: account,
      customer: customer
    } do
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-01 12:00:00]})
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-02 12:00:00]})
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-03 12:00:00]})

      assert [
               %{date: ~D[2020-09-01], count: 1},
               %{date: ~D[2020-09-02], count: 1},
               %{date: ~D[2020-09-03], count: 1}
             ] = Reporting.count_conversations_by_date(account.id)
    end

    test "count_conversations_by_date/3 fetches conversations between two dates", %{
      account: account,
      customer: customer
    } do
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-01 12:00:00]})
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-02 12:00:00]})
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-03 12:00:00]})
      conversation_fixture(account, customer, %{inserted_at: ~N[2020-09-04 12:00:00]})

      assert [
               %{date: ~D[2020-09-02], count: 1},
               %{date: ~D[2020-09-03], count: 1}
             ] =
               Reporting.count_conversations_by_date(
                 account.id,
                 ~N[2020-09-02 11:00:00],
                 ~N[2020-09-03 13:00:00]
               )
    end

    test "count_sent_messages_by_date/1 groups by date correctly", %{
      account: account,
      customer: customer
    } do
      user_2 = user_fixture(account)
      user_3 = user_fixture(account)
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-01 12:00:00],
        user_id: user_2.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-02 12:00:00],
        user_id: user_2.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        user_id: user_3.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        user_id: user_3.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        customer_id: customer.id
      })

      assert [
               %{date: ~D[2020-09-01], count: 1},
               %{date: ~D[2020-09-02], count: 1},
               %{date: ~D[2020-09-03], count: 2}
             ] = Reporting.count_sent_messages_by_date(account.id)
    end

    test "count_received_messages_by_date/1 groups by date correctly", %{
      account: account,
      customer: customer
    } do
      user_2 = user_fixture(account)
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-01 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-02 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        user_id: user_2.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-03 12:00:00],
        user_id: user_2.id
      })

      assert [
               %{date: ~D[2020-09-01], count: 1},
               %{date: ~D[2020-09-02], count: 1},
               %{date: ~D[2020-09-03], count: 1}
             ] = Reporting.count_received_messages_by_date(account.id)
    end
  end

  describe "count_messages_by_weekday/1" do
    setup do
      account = account_fixture()
      customer = customer_fixture(account)

      {:ok, account: account, customer: customer}
    end

    test "correctly calculates total and avg of customer messages per day",
         %{
           account: account,
           customer: customer
         } do
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-28 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-29 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-29 12:01:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-30 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-10-01 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-10-02 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-10-03 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-10-04 12:00:00],
        customer_id: customer.id
      })

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-10-05 12:00:00],
        customer_id: customer.id
      })

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

    test "includes zero day counts for weekdays with no messages", %{
      account: account,
      customer: customer
    } do
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{
        inserted_at: ~N[2020-09-28 12:00:00],
        customer_id: customer.id
      })

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

    test "doesn't count messages without a customer", %{
      account: account,
      customer: customer
    } do
      conversation = conversation_fixture(account, customer)

      message_fixture(account, conversation, %{inserted_at: ~N[2020-09-28 12:00:00]})

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

    test "doesn't count messages from other accounts", %{
      account: account,
      customer: customer
    } do
      different_account = account_fixture()
      conversation = conversation_fixture(different_account, customer)

      message_fixture(different_account, conversation, %{
        inserted_at: ~N[2020-09-28 12:00:00],
        customer_id: customer.id
      })

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
      account = account_fixture()

      {:ok, account: account}
    end

    test "it groups by date correctly", %{
      account: account
    } do
      customer_fixture(account, %{
        inserted_at: ~N[2020-10-12 12:00:00]
      })

      customer_fixture(account, %{
        inserted_at: ~N[2020-10-11 12:00:00]
      })

      customer_fixture(account, %{
        inserted_at: ~N[2020-10-10 12:00:00]
      })

      customer_fixture(account, %{
        inserted_at: ~N[2020-10-12 12:00:00]
      })

      assert [
               %{date: ~D[2020-10-10], count: 1},
               %{date: ~D[2020-10-11], count: 1},
               %{date: ~D[2020-10-12], count: 2}
             ] = Reporting.count_customers_by_date(account.id)
    end
  end

  describe "count_customers_by_date/3" do
    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "Fetches customers between two dates", %{
      account: account
    } do
      customer_fixture(account, %{
        inserted_at: ~N[2020-10-12 12:00:00]
      })

      customer_fixture(account, %{
        inserted_at: ~N[2020-10-11 12:00:00]
      })

      customer_fixture(account, %{
        inserted_at: ~N[2020-10-10 12:00:00]
      })

      customer_fixture(account, %{
        inserted_at: ~N[2020-10-13 12:00:00]
      })

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
