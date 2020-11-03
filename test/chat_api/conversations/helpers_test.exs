defmodule ChatApi.Conversations.HelpersTest do
  use ChatApi.DataCase

  import ExUnit.CaptureLog

  alias ChatApi.Conversations.Helpers

  describe "ChatApi.Conversations.Helpers" do
    setup do
      account = account_fixture()
      customer = customer_fixture(account)
      conversation = conversation_fixture(account, customer)

      {:ok, conversation: conversation, account: account, customer: customer}
    end

    test "send_conversation_state_update/2 sends a state update Slack when given a valid status or priority",
         %{conversation: conversation} do
      assert Helpers.send_conversation_state_update(conversation, %{"status" => "open"}) ==
               {:ok, "This conversation has been reopened."}

      assert Helpers.send_conversation_state_update(conversation, %{"priority" => "priority"}) ==
               {:ok, "This conversation has been prioritized."}
    end

    test "send_conversation_state_update/2 does not send an update to Slack when given an invalid status or priority",
         %{conversation: conversation} do
      assert Helpers.send_conversation_state_update(conversation, %{"status" => "BOOM"}) ==
               {:error, "state_invalid"}

      assert Helpers.send_conversation_state_update(conversation, %{"priority" => "BOOM"}) ==
               {:error, "state_invalid"}
    end
  end
end
