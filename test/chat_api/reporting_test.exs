defmodule ChatApi.ReportingTest do
  use ChatApi.DataCase

  alias ChatApi.Reporting

  describe "reporting" do
    setup do
      account = account_fixture()
      customer = customer_fixture(account)

      {:ok, account: account, customer: customer}
    end

    test "messages_by_day/0 retrieves the number of messages created per day", %{
      account: account,
      customer: customer
    } do
      count = 10
      conversation = conversation_fixture(account, customer)

      for _i <- 1..count, do: message_fixture(account, conversation)

      assert [%{count: ^count, date: _date}] = Reporting.messages_by_day()
    end

    test "conversations_by_day/0 retrieves the number of conversations created per day", %{
      account: account,
      customer: customer
    } do
      count = 5

      for _i <- 1..count, do: conversation_fixture(account, customer)

      assert [%{count: ^count, date: _date}] = Reporting.conversations_by_day()
    end
  end
end
