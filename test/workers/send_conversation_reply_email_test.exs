defmodule ChatApi.SendConversationReplyEmailTest do
  use ChatApi.DataCase, async: true

  import ExUnit.CaptureLog
  import ChatApi.Factory

  setup do
    account = insert(:account)
    user = insert(:user, account: account)
    customer = insert(:customer, account: account)

    {:ok, account: account, customer: customer, user: user}
  end

  describe "send_email/1" do
    test "skips sending if the latest message was from a customer", %{
      account: account,
      customer: customer
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          customer: customer,
          user: nil,
          seen_at: nil
        )

      assert :skipped =
               ChatApi.Workers.SendConversationReplyEmail.send_email(%{
                 "seen_at" => message.seen_at,
                 "user_id" => message.user_id,
                 "user" => message.user,
                 "account_id" => message.account_id,
                 "customer_id" => message.customer_id,
                 "conversation_id" => message.conversation_id
               })
    end

    test "skips sending if the conversation originated in Slack", %{
      account: account,
      customer: customer,
      user: user
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "slack")

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil,
          seen_at: nil
        )

      assert :skipped =
               ChatApi.Workers.SendConversationReplyEmail.send_email(%{
                 "seen_at" => message.seen_at,
                 "user_id" => message.user_id,
                 "user" => message.user,
                 "account_id" => message.account_id,
                 "customer_id" => message.customer_id,
                 "conversation_id" => message.conversation_id
               })
    end

    test "skips sending if the conversation has no unread messages", %{
      account: account,
      customer: customer,
      user: user
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil,
          seen_at: ~U[2020-12-08 10:00:00Z]
        )

      assert :skipped =
               ChatApi.Workers.SendConversationReplyEmail.send_email(%{
                 "seen_at" => nil,
                 "user_id" => message.user_id,
                 "user" => message.user,
                 "account_id" => message.account_id,
                 "customer_id" => message.customer_id,
                 "conversation_id" => message.conversation_id
               })
    end

    test "sends if the conversation has unread messages", %{
      account: account,
      customer: customer,
      user: user
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          customer: nil,
          seen_at: nil
        )

      assert capture_log(fn ->
               result =
                 ChatApi.Workers.SendConversationReplyEmail.send_email(%{
                   "seen_at" => message.seen_at,
                   "user_id" => message.user_id,
                   "user" => message.user,
                   "account_id" => message.account_id,
                   "customer_id" => message.customer_id,
                   "conversation_id" => message.conversation_id
                 })

               assert result == :ok
             end) =~ "Skipped sending"
    end

    test "handles invalid input" do
      assert :error =
               ChatApi.Workers.SendConversationReplyEmail.send_email(%{
                 "foo" => "bar"
               })
    end
  end

  describe "should_send_email?/1" do
    test "should_send_email?/1 returns false if the conversation is not from a chat", %{
      account: account,
      customer: customer
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "slack")

      refute ChatApi.Workers.SendConversationReplyEmail.should_send_email?(conversation.id)
    end

    test "should_send_email?/1 returns false if the conversation has no unread messages and is from a 'chat'",
         %{
           account: account,
           customer: customer,
           user: user
         } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      insert(:message,
        account: account,
        conversation: conversation,
        user: user,
        seen_at: ~U[2020-12-06 10:00:00Z]
      )

      insert(:message,
        account: account,
        conversation: conversation,
        user: user,
        seen_at: ~U[2020-12-07 10:00:00Z]
      )

      insert(:message,
        account: account,
        conversation: conversation,
        user: user,
        seen_at: ~U[2020-12-08 10:00:00Z]
      )

      refute ChatApi.Workers.SendConversationReplyEmail.should_send_email?(conversation.id)
    end

    test "should_send_email?/1 returns true if the conversation has unread messages and is from a 'chat'",
         %{
           account: account,
           customer: customer,
           user: user
         } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      insert(:message,
        account: account,
        conversation: conversation,
        user: user,
        seen_at: ~U[2020-12-06 10:00:00Z]
      )

      insert(:message,
        account: account,
        conversation: conversation,
        user: user,
        seen_at: nil
      )

      insert(:message,
        account: account,
        conversation: conversation,
        user: user,
        seen_at: ~U[2020-12-08 10:00:00Z]
      )

      assert ChatApi.Workers.SendConversationReplyEmail.should_send_email?(conversation.id)
    end
  end
end
