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

    test "formats the email properly", %{
      account: account,
      customer: customer,
      user: user
    } do
      conversation = insert(:conversation, account: account, customer: customer, source: "chat")

      messages = [
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          body: "This is a test with plain text",
          customer: nil,
          seen_at: nil
        ),
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          body: "This is a test _with_ **markdown** [woot](https://papercups.io)",
          customer: nil,
          seen_at: nil
        )
      ]

      email =
        ChatApi.Emails.Email.conversation_reply(
          to: customer.email,
          from: "Papercups Test",
          reply_to: user.email,
          company: account.company_name,
          messages: messages,
          customer: customer
        )

      assert email.html_body =~ "This is a test with plain text"

      assert email.html_body =~
               "This is a test <em>with</em> <strong>markdown</strong> <a href=\"https://papercups.io\">woot</a>"
    end

    test "handles invalid input" do
      assert :error =
               ChatApi.Workers.SendConversationReplyEmail.send_email(%{
                 "foo" => "bar"
               })
    end
  end

  describe "get_recent_messages/2" do
    test "get_recent_messages/2 returns up to 5 recent public messages", %{
      account: account
    } do
      conversation = insert(:conversation, account: account)
      insert_list(10, :message, account: account, conversation: conversation)

      message_ids =
        conversation.id
        |> ChatApi.Workers.SendConversationReplyEmail.get_recent_messages(account.id)
        |> Enum.map(& &1.id)

      assert length(message_ids) == 5
    end

    test "get_recent_messages/2 does not include private messages", %{
      account: account
    } do
      conversation = insert(:conversation, account: account)

      public_a =
        insert(:message,
          account: account,
          conversation: conversation,
          inserted_at: ~N[2021-06-01 20:00:00]
        )

      _private_message =
        insert(:message,
          account: account,
          conversation: conversation,
          private: true,
          inserted_at: ~N[2021-06-02 20:00:00]
        )

      public_b =
        insert(:message,
          account: account,
          conversation: conversation,
          inserted_at: ~N[2021-06-03 20:00:00]
        )

      message_ids =
        conversation.id
        |> ChatApi.Workers.SendConversationReplyEmail.get_recent_messages(account.id)
        |> Enum.map(& &1.id)

      assert message_ids == [public_a.id, public_b.id]
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
