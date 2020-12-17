defmodule ChatApi.SlackTest do
  use ChatApi.DataCase

  import ExUnit.CaptureLog
  import ChatApi.Factory

  alias ChatApi.{
    Conversations,
    Slack,
    SlackConversationThreads,
    Users
  }

  describe "Slack.Token" do
    test "Token.is_valid_access_token?/1 checks the validity of an access token" do
      assert Slack.Token.is_valid_access_token?("invalid") == false
      assert Slack.Token.is_valid_access_token?("xoxb-xxx-xxxxx-xxx") == true
    end
  end

  describe "Slack.Helpers" do
    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)
      thread = insert(:slack_conversation_thread, account: account, conversation: conversation)

      {:ok, conversation: conversation, account: account, customer: customer, thread: thread}
    end

    test "Helpers.get_message_text/1 returns subject for initial slack thread",
         %{conversation: conversation, customer: customer} do
      text =
        Slack.Helpers.get_message_text(%{
          customer: customer,
          text: "Test message",
          conversation_id: conversation.id,
          type: :customer,
          thread: nil
        })

      assert String.contains?(text, customer.email)
      assert String.contains?(text, conversation.id)
      assert String.contains?(text, "Reply to this thread to start chatting")
    end

    test "Helpers.get_message_text/1 returns subject for slack reply",
         %{conversation: conversation, customer: customer, thread: thread} do
      assert Slack.Helpers.get_message_text(%{
               text: "Test message",
               conversation_id: conversation.id,
               customer: customer,
               type: :agent,
               thread: thread
             }) ==
               "*:female-technologist: Agent*: Test message"

      assert Slack.Helpers.get_message_text(%{
               text: "Test message",
               conversation_id: conversation.id,
               customer: customer,
               type: :customer,
               thread: thread
             }) ==
               "*:wave: #{customer.email}*: Test message"

      assert_raise ArgumentError, fn ->
        Slack.Helpers.get_message_text(%{
          text: "Test message",
          conversation_id: conversation.id,
          customer: customer,
          type: :invalid,
          thread: thread
        })
      end
    end

    test "Helpers.get_message_payload/2 returns payload for initial slack thread",
         %{customer: customer, thread: thread} do
      text = "Hello world"
      customer_email = "*Email:*\n#{customer.email}"
      channel = thread.slack_channel

      assert %{
               "blocks" => [
                 %{
                   "text" => %{
                     "text" => ^text
                   }
                 },
                 %{
                   "fields" => [
                     %{
                       "text" => "*Name:*\nAnonymous User"
                     },
                     %{
                       "text" => ^customer_email
                     },
                     %{
                       "text" => "*URL:*\nN/A"
                     },
                     %{
                       "text" => "*Browser:*\nN/A"
                     },
                     %{
                       "text" => "*OS:*\nN/A"
                     },
                     %{
                       "text" => "*Timezone:*\nN/A"
                     }
                   ]
                 }
               ],
               "channel" => ^channel
             } =
               Slack.Helpers.get_message_payload(text, %{
                 channel: channel,
                 customer: customer,
                 thread: nil
               })
    end

    test "Helpers.get_message_payload/2 returns payload for slack reply",
         %{thread: thread} do
      text = "Hello world"
      ts = thread.slack_thread_ts
      channel = thread.slack_channel

      assert %{
               "channel" => ^channel,
               "text" => ^text,
               "thread_ts" => ^ts
             } =
               Slack.Helpers.get_message_payload(text, %{
                 channel: channel,
                 thread: thread,
                 customer: nil
               })
    end

    test "Helpers.extract_slack_conversation_thread_info/1 extracts thread info from slack response" do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert %{slack_channel: ^channel, slack_thread_ts: ^ts} =
               Slack.Helpers.extract_slack_conversation_thread_info(response)
    end

    test "Helpers.extract_slack_conversation_thread_info/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.Helpers.extract_slack_conversation_thread_info(response)
               end
             end) =~ "Error sending Slack message"
    end

    test "Helpers.extract_slack_user_email/1 extracts user's email from slack response" do
      email = "test@test.com"
      response = %{body: %{"ok" => true, "user" => %{"profile" => %{"email" => email}}}}

      assert email = Slack.Helpers.extract_slack_user_email(response)
    end

    test "Helpers.extract_slack_user_email/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false, "user" => nil}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.Helpers.extract_slack_user_email(response)
               end
             end) =~ "Error retrieving user info"
    end

    test "Helpers.create_new_slack_conversation_thread/2 creates a new thread and assigns the primary user",
         %{conversation: conversation, account: account} do
      %{account_id: account_id, id: id} = conversation
      primary_user = insert(:user, account: account)
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      {:ok, thread} = Slack.Helpers.create_new_slack_conversation_thread(id, response)

      assert %SlackConversationThreads.SlackConversationThread{
               slack_channel: ^channel,
               slack_thread_ts: ^ts,
               account_id: ^account_id,
               conversation_id: ^id
             } = thread

      conversation = Conversations.get_conversation!(id)

      assert conversation.assignee_id == primary_user.id
    end

    test "Helpers.create_new_slack_conversation_thread/2 raises if no primary user exists",
         %{conversation: conversation} do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert_raise RuntimeError, fn ->
        Slack.Helpers.create_new_slack_conversation_thread(conversation.id, response)
      end
    end

    test "Helpers.get_conversation_primary_user_id/2 gets the primary user of the associated account" do
      account = insert(:account)
      user = insert(:user, account: account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)
      conversation = Conversations.get_conversation_with!(conversation.id, account: :users)

      assert Slack.Helpers.get_conversation_primary_user_id(conversation) == user.id
    end

    test "Helpers.fetch_valid_user/1 reject disabled users and fetch the oldest user.",
         %{account: account} do
      {:ok, disabled_user} =
        insert(:user, account: account)
        |> Users.disable_user()

      primary_user = insert(:user, account: account)

      # Make sure that secondary_user is inserted later.
      :timer.sleep(1000)
      secondary_user = insert(:user, account: account)

      users = [disabled_user, secondary_user, primary_user]
      assert primary_user.id === Slack.Helpers.fetch_valid_user(users)
    end

    test "Helpers.identify_customer/1 returns the message sender type", %{account: account} do
      jane = insert(:customer, account: account, name: "Jane", email: "jane@jane.com")
      bob = insert(:customer, account: account, email: "bob@bob.com", name: nil)
      test = insert(:customer, account: account, name: "Test User", email: nil)
      anon = insert(:customer, account: account, name: nil, email: nil)

      assert Slack.Helpers.identify_customer(jane) == "Jane (jane@jane.com)"
      assert Slack.Helpers.identify_customer(bob) == "bob@bob.com"
      assert Slack.Helpers.identify_customer(test) == "Test User"
      assert Slack.Helpers.identify_customer(anon) == "Anonymous User"
    end

    test "Helpers.get_message_type/1 returns the message sender type" do
      customer_message = insert(:message, user: nil)
      user_message = insert(:message, customer: nil)

      assert :customer = Slack.Helpers.get_message_type(customer_message)
      assert :agent = Slack.Helpers.get_message_type(user_message)
    end
  end
end
