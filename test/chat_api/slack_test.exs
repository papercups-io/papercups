defmodule ChatApi.SlackTest do
  use ChatApi.DataCase

  import ExUnit.CaptureLog

  alias ChatApi.{
    Accounts,
    Conversations,
    Customers,
    Slack,
    SlackConversationThreads,
    Users.User
  }

  describe "slack" do
    # TODO: start moving to factories
    def account_fixture(_attrs \\ %{}) do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      account
    end

    def customer_fixture(attrs \\ %{}) do
      account = account_fixture()

      {:ok, customer} =
        %{
          first_seen: ~D[2020-01-01],
          last_seen: ~D[2020-01-01],
          email: "test@test.com",
          account_id: account.id
        }
        |> Enum.into(attrs)
        |> Customers.create_customer()

      customer
    end

    def user_fixture(account_id) do
      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        password: "secret1234",
        password_confirmation: "secret1234",
        account_id: account_id
      })
      |> Repo.insert!()
    end

    def conversation_fixture(attrs \\ %{}) do
      %{id: account_id} = account_fixture()
      %{id: customer_id} = customer_fixture()

      {:ok, conversation} =
        %{
          status: "open",
          account_id: account_id,
          customer_id: customer_id
        }
        |> Enum.into(attrs)
        |> Conversations.create_conversation()

      conversation
    end

    def slack_conversation_thread_fixture(_attrs \\ %{}) do
      %{id: conversation_id, account_id: account_id} = conversation_fixture()

      {:ok, slack_conversation_thread} =
        SlackConversationThreads.create_slack_conversation_thread(%{
          account_id: account_id,
          conversation_id: conversation_id,
          slack_thread_ts: "1234.56789",
          slack_channel: "bots"
        })

      slack_conversation_thread
    end

    test "get_conversation_account_id/1 returns a valid account_id" do
      conversation = conversation_fixture()
      account_id = Slack.get_conversation_account_id(conversation.id)

      assert account_id
    end

    test "is_valid_access_token?/1 checks the validity of an access token" do
      assert Slack.is_valid_access_token?("invalid") == false
      assert Slack.is_valid_access_token?("xoxb-xxx-xxxxx-xxx") == true
    end

    test "get_slack_message_subject!/4 returns subject for initial slack thread" do
      customer = customer_fixture()
      conversation = conversation_fixture(%{customer_id: customer.id})
      thread = nil
      subject = Slack.get_slack_message_subject!(:customer, customer, conversation.id, thread)

      assert String.contains?(subject, customer.email)
      assert String.contains?(subject, conversation.id)
      assert String.contains?(subject, "Reply to this thread to start chatting")
    end

    test "get_slack_message_subject!/4 returns subject for slack reply" do
      customer = customer_fixture()
      thread = slack_conversation_thread_fixture()
      %{conversation_id: conversation_id} = thread

      assert Slack.get_slack_message_subject!(:agent, customer, conversation_id, thread) ==
               ":female-technologist: Agent:"

      assert Slack.get_slack_message_subject!(:customer, customer, conversation_id, thread) ==
               ":wave: #{customer.email}:"

      assert_raise ArgumentError, fn ->
        Slack.get_slack_message_subject!(:invalid, customer, conversation_id, thread)
      end
    end

    test "get_slack_message_payload/4 returns payload for initial slack thread" do
      channel = "bots"
      subject = "New Slack thread!"
      text = "Hello world"
      thread = nil

      assert %{
               "attachments" => attachments,
               "channel" => ^channel,
               "text" => ^subject
             } = Slack.get_slack_message_payload(subject, channel, text, thread)
    end

    test "get_slack_message_payload/4 returns payload for slack reply" do
      channel = "bots"
      subject = "New Slack thread!"
      text = "Hello world"
      thread = slack_conversation_thread_fixture()

      assert %{
               "attachments" => attachments,
               "channel" => ^channel,
               "text" => ^subject,
               "thread_ts" => thread_ts
             } = Slack.get_slack_message_payload(subject, channel, text, thread)
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

    test "create_new_slack_conversation_thread/2 creates a new thread and assigns the primary user" do
      %{id: conversation_id, account_id: account_id} = conversation_fixture()
      primary_user = user_fixture(account_id)
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      {:ok, thread} = Slack.create_new_slack_conversation_thread(conversation_id, response)

      assert %SlackConversationThreads.SlackConversationThread{
               slack_channel: ^channel,
               slack_thread_ts: ^ts,
               account_id: ^account_id,
               conversation_id: ^conversation_id
             } = thread

      conversation = Conversations.get_conversation!(conversation_id)

      assert conversation.assignee_id == primary_user.id
    end

    test "create_new_slack_conversation_thread/2 raises if no primary user exists" do
      %{id: conversation_id} = conversation_fixture()
      channel = "bots"
      ts = "1234.56789"
      response = %{body: %{"ok" => true, "channel" => channel, "ts" => ts}}

      assert_raise RuntimeError, fn ->
        Slack.create_new_slack_conversation_thread(conversation_id, response)
      end
    end
  end
end
