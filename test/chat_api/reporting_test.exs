defmodule ChatApi.ReportingTest do
  use ChatApi.DataCase

  alias ChatApi.Reporting

  describe "reporting" do
    setup do
      account = account_fixture()
      customer = customer_fixture(account)

      {:ok, account: account, customer: customer}
    end

    test "messages_by_date/1 retrieves the number of messages created per day", %{
      account: account,
      customer: customer
    } do
      count = 10
      inserted_at = ~N[2020-09-01 12:00:00]
      conversation = conversation_fixture(account, customer)

      for _i <- 1..count do
        message_fixture(account, conversation, %{inserted_at: inserted_at})
      end

      assert [%{count: ^count, date: ~D[2020-09-01]}] = Reporting.messages_by_date(account.id)
    end

    test "messages_by_date/1 groups by date correctly", %{
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
             ] = Reporting.messages_by_date(account.id)
    end

    test "messages_by_date/1 only fetches messages by the given account id", %{
      account: account,
      customer: customer
    } do
      conversation = conversation_fixture(account, customer)
      message_fixture(account, conversation, %{inserted_at: ~N[2020-09-01 12:00:00]})

      assert [%{date: ~D[2020-09-01], count: 1}] = Reporting.messages_by_date(account.id)

      different_account = account_fixture()

      assert [] = Reporting.messages_by_date(different_account.id)
    end

    test "conversations_by_date/1 retrieves the number of conversations created per day", %{
      account: account,
      customer: customer
    } do
      count = 5
      inserted_at = ~N[2020-09-01 12:00:00]

      for _i <- 1..count do
        conversation_fixture(account, customer, %{inserted_at: inserted_at})
      end

      assert [%{count: ^count, date: ~D[2020-09-01]}] =
               Reporting.conversations_by_date(account.id)
    end

    test "conversations_by_date/1 groups by date correctly", %{
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
             ] = Reporting.conversations_by_date(account.id)
    end
  end
end
