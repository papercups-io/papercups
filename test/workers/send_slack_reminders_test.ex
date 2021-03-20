defmodule ChatApi.SendConversationReplyEmailTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory

  setup do
    account = insert(:account)
    user = insert(:user, account: account)
    customer = insert(:customer, account: account)

    {:ok, account: account, customer: customer, user: user}
  end

  describe "list_forgotten_conversations/0" do
    test "finds no conversations if no messages", %{
      account: account,
      customer: customer
    } do
      insert(:conversation, account: account, customer: customer, source: "chat")

      assert [] = ChatApi.Workers.SendSlackReminders.list_forgotten_conversations()
    end

    test "finds conversation only if last message was from customer, sent more than 24 hours ago",
         %{
           account: account,
           customer: customer,
           user: user
         } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      insert(:message,
        body: "I am a customer",
        account: account,
        conversation: conversation,
        customer: customer,
        user: nil,
        sent_at: DateTime.add(DateTime.utc_now(), -:timer.hours(26), :millisecond)
      )

      assert [conversation] = ChatApi.Workers.SendSlackReminders.list_forgotten_conversations()

      insert(:message,
        body: "Hello customer, I am a user",
        account: account,
        conversation: conversation,
        customer: nil,
        user: user,
        sent_at: DateTime.add(DateTime.utc_now(), -:timer.hours(25), :millisecond)
      )

      assert [] = ChatApi.Workers.SendSlackReminders.list_forgotten_conversations()

      insert(:message,
        body: "Hello user, customer here. goodbye now",
        account: account,
        conversation: conversation,
        customer: customer,
        user: nil,
        seen_at: nil,
        sent_at: DateTime.add(DateTime.utc_now(), -:timer.hours(3), :millisecond)
      )

      assert [] = ChatApi.Workers.SendSlackReminders.list_forgotten_conversations()
    end
  end

  describe "find_slackable_users/1" do
    test "works with no conversations" do
      assert [] = ChatApi.Workers.SendSlackReminders.find_slackable_users([])
    end

    test "filters conversations without assignees", %{
      account: account,
      customer: customer
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      assert [] = ChatApi.Workers.SendSlackReminders.find_slackable_users([conversation])
    end

    test "gets users if they have a slack_user_id in their profiel", %{
      account: account,
      customer: customer,
      user: user
    } do
      conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          source: "chat",
          assignee_id: user.id
        )

      assert [] = ChatApi.Workers.SendSlackReminders.find_slackable_users([conversation])

      insert(:user_profile,
        user: user,
        slack_user_id: "some_id"
      )

      assert [user] = ChatApi.Workers.SendSlackReminders.find_slackable_users([conversation])
    end
  end
end
