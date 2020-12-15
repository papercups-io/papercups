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

  describe "slack" do
    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)
      thread = insert(:slack_conversation_thread, account: account, conversation: conversation)

      {:ok, conversation: conversation, account: account, customer: customer, thread: thread}
    end

    test "get_conversation_account_id/1 returns a valid account_id",
         %{conversation: conversation} do
      account_id = Slack.get_conversation_account_id(conversation.id)

      assert account_id
    end

    test "is_valid_access_token?/1 checks the validity of an access token" do
      assert Slack.is_valid_access_token?("invalid") == false
      assert Slack.is_valid_access_token?("xoxb-xxx-xxxxx-xxx") == true
    end

    test "get_message_text/1 returns subject for initial slack thread",
         %{conversation: conversation, customer: customer} do
      text =
        Slack.get_message_text(%{
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

    test "get_message_text/1 returns subject for slack reply",
         %{conversation: conversation, customer: customer, thread: thread} do
      assert Slack.get_message_text(%{
               text: "Test message",
               conversation_id: conversation.id,
               customer: customer,
               type: :agent,
               thread: thread
             }) ==
               "*:female-technologist: Agent*: Test message"

      assert Slack.get_message_text(%{
               text: "Test message",
               conversation_id: conversation.id,
               customer: customer,
               type: :customer,
               thread: thread
             }) ==
               "*:wave: #{customer.email}*: Test message"

      assert_raise ArgumentError, fn ->
        Slack.get_message_text(%{
          text: "Test message",
          conversation_id: conversation.id,
          customer: customer,
          type: :invalid,
          thread: thread
        })
      end
    end

    test "get_message_payload/2 returns payload for initial slack thread",
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
               Slack.get_message_payload(text, %{
                 channel: channel,
                 customer: customer,
                 thread: nil
               })
    end

    test "get_message_payload/2 returns payload for slack reply",
         %{thread: thread} do
      text = "Hello world"
      ts = thread.slack_thread_ts
      channel = thread.slack_channel

      assert %{
               "channel" => ^channel,
               "text" => ^text,
               "thread_ts" => ^ts
             } =
               Slack.get_message_payload(text, %{
                 channel: channel,
                 thread: thread,
                 customer: nil
               })
    end

    test "extract_slack_conversation_thread_info/1 extracts thread info from slack response" do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert %{slack_channel: ^channel, slack_thread_ts: ^ts} =
               Slack.extract_slack_conversation_thread_info(response)
    end

    test "extract_slack_conversation_thread_info/1 raises if the slack response has ok=false" do
      response = %{body: %{"ok" => false}}

      assert capture_log(fn ->
               assert_raise RuntimeError, fn ->
                 Slack.extract_slack_conversation_thread_info(response)
               end
             end) =~ "Error sending Slack message"
    end

    test "create_new_slack_conversation_thread/2 creates a new thread and assigns the primary user",
         %{conversation: conversation, account: account} do
      %{account_id: account_id, id: id} = conversation
      primary_user = insert(:user, account: account)
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      {:ok, thread} = Slack.create_new_slack_conversation_thread(id, response)

      assert %SlackConversationThreads.SlackConversationThread{
               slack_channel: ^channel,
               slack_thread_ts: ^ts,
               account_id: ^account_id,
               conversation_id: ^id
             } = thread

      conversation = Conversations.get_conversation!(id)

      assert conversation.assignee_id == primary_user.id
    end

    test "fetch_valid_user/1 reject disabled users and fetch the oldest user.",
         %{account: account} do
      {:ok, disabled_user} =
        insert(:user, account: account)
        |> Users.disable_user()

      primary_user = insert(:user, account: account)

      # Make sure that secondary_user is inserted later.
      :timer.sleep(1000)
      secondary_user = insert(:user, account: account)

      users = [disabled_user, secondary_user, primary_user]
      assert primary_user.id === Slack.fetch_valid_user(users)
    end

    test "create_new_slack_conversation_thread/2 raises if no primary user exists",
         %{conversation: conversation} do
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert_raise RuntimeError, fn ->
        Slack.create_new_slack_conversation_thread(conversation.id, response)
      end
    end
  end
end
