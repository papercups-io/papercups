defmodule ChatApi.Conversations.HelpersTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.{Conversations, Conversations.Helpers}

  describe "ChatApi.Conversations.Helpers" do
    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)

      {:ok, conversation: conversation, account: account, customer: customer}
    end

    test "send_conversation_state_update/2 sends a state update Slack when given a valid status or priority",
         %{conversation: conversation} do
      assert Helpers.send_conversation_state_update(conversation, %{"status" => "open"}) ==
               {:ok, ":outbox_tray: This conversation has been reopened."}

      assert Helpers.send_conversation_state_update(conversation, %{"priority" => "priority"}) ==
               {:ok, ":star: This conversation has been prioritized."}

      assert Helpers.send_conversation_state_update(conversation, %{"state" => "deleted"}) ==
               {:ok, ":wastebasket: This conversation has been deleted."}
    end

    test "send_conversation_state_update/2 does not send an update to Slack when given an invalid status or priority",
         %{conversation: conversation} do
      assert Helpers.send_conversation_state_update(conversation, %{"status" => "BOOM"}) ==
               {:error, "state_invalid"}

      assert Helpers.send_conversation_state_update(conversation, %{"priority" => "BOOM"}) ==
               {:error, "state_invalid"}

      assert Helpers.send_conversation_state_update(conversation, %{"state" => "BOOM"}) ==
               {:error, "state_invalid"}
    end

    test "send_multiple_archived_updates/2 sends archived updates to multiple conversations",
         %{account: account, customer: customer} do
      past = DateTime.add(DateTime.utc_now(), -:timer.hours(336), :millisecond)

      insert_list(3, :conversation, %{
        account: account,
        customer: customer,
        updated_at: past,
        status: "closed"
      })

      archived_conversations = Conversations.query_conversations_closed_for(days: 14)

      assert Helpers.send_multiple_archived_updates(ChatApi.Repo.all(archived_conversations)) == [
               ok: ":file_cabinet: This conversation has been archived.",
               ok: ":file_cabinet: This conversation has been archived.",
               ok: ":file_cabinet: This conversation has been archived."
             ]
    end
  end
end
