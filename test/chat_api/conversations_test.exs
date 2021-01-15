defmodule ChatApi.ConversationsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory

  alias ChatApi.Repo
  alias ChatApi.{Conversations, SlackConversationThreads}

  describe "conversations" do
    alias ChatApi.Conversations.Conversation
    alias ChatApi.SlackConversationThreads.SlackConversationThread
    alias ChatApi.Messages.Message

    @update_attrs %{status: "closed"}
    @invalid_attrs %{status: nil}

    setup do
      account = insert(:account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)

      {:ok, account: account, conversation: conversation, customer: customer}
    end

    test "list_conversations/0 returns all conversations",
         %{conversation: conversation} do
      result_ids = Conversations.list_conversations() |> Enum.map(& &1.id)

      assert result_ids == [conversation.id]
    end

    test "list_conversations_by_account/1 returns all conversations for an account",
         %{account: account, conversation: conversation} do
      result_ids = Enum.map(Conversations.list_conversations_by_account(account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "list_conversations_by_account/1 sorts the conversations by most recent message",
         %{account: account, customer: customer, conversation: conversation_1} do
      [conversation_2, conversation_3] =
        insert_pair(:conversation, account: account, customer: customer)

      insert(:message,
        account: account,
        conversation: conversation_2,
        inserted_at: ~N[2020-11-02 20:00:00]
      )

      insert(:message,
        account: account,
        conversation: conversation_3,
        inserted_at: ~N[2020-11-03 20:00:00]
      )

      results = Conversations.list_conversations_by_account(account.id)
      result_ids = Enum.map(results, & &1.id)

      # Sorted by conversation with most recent message to least recent
      assert result_ids == [conversation_1.id, conversation_3.id, conversation_2.id]
    end

    test "list_conversations_by_account/1 returns all not archived conversations for an account",
         %{account: account, conversation: conversation} do
      not_archived_conversation = insert(:conversation, account: account)
      _archived_conversation = Conversations.archive_conversation(conversation)

      result_ids = Enum.map(Conversations.list_conversations_by_account(account.id), & &1.id)

      assert result_ids == [not_archived_conversation.id]
    end

    test "find_by_customer/2 returns all conversations for a customer",
         %{account: account, conversation: conversation, customer: customer} do
      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "find_by_customer/2 does not include archived conversations for a customer",
         %{account: account, conversation: conversation, customer: customer} do
      _archived_conversation =
        insert(:conversation, account: account, customer: customer)
        |> Conversations.archive_conversation()

      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "find_by_customer/2 does not include closed conversations for a customer",
         %{account: account, customer: customer} do
      closed = insert(:conversation, account: account, customer: customer, status: "closed")

      results = Conversations.find_by_customer(customer.id, account.id)
      ids = Enum.map(results, & &1.id)

      refute Enum.member?(ids, closed.id)
      assert Enum.all?(results, fn conv -> conv.status == "open" end)
    end

    test "find_by_customer/2 does not include private messages in the conversation results",
         %{account: account, customer: customer, conversation: conversation} do
      user = insert(:user, account: account)

      reply =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          body: "This should be visible!"
        )

      _private =
        insert(:message,
          account: account,
          conversation: conversation,
          user: user,
          private: true,
          type: "note",
          body: "This should be hidden!"
        )

      assert [conversation] = Conversations.find_by_customer(customer.id, account.id)
      assert [message] = conversation.messages
      assert message.body == reply.body
      refute message.private
    end

    test "get_conversation!/1 returns the conversation with given id",
         %{conversation: conversation} do
      found_conversation = Conversations.get_conversation!(conversation.id)

      assert found_conversation.id == conversation.id
    end

    test "create_conversation/1 with valid data creates a conversation" do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(params_with_assocs(:conversation))

      assert conversation.status == "open"
      assert conversation.source == "chat"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "create_conversation/1 with invalid source returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               Conversations.create_conversation(%{status: "closed", source: "unknown"})

      assert {"is invalid", _} = errors[:source]
    end

    test "update_conversation/2 with valid data updates the conversation",
         %{conversation: conversation} do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.update_conversation(conversation, @update_attrs)

      assert conversation.status == "closed"
    end

    test "update_conversation/2 with invalid data returns error changeset",
         %{conversation: conversation} do
      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation(conversation, @invalid_attrs)

      assert _conversation = Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation",
         %{conversation: conversation} do
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "delete_conversation/1 deletes the conversation if associated slack_conversation_threads exist" do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(params_with_assocs(:conversation))

      slack_conversation_thread_attrs = %{
        slack_channel: "some slack_channel",
        slack_thread_ts: "some slack_thread_ts",
        conversation_id: conversation.id,
        account_id: conversation.account_id
      }

      assert {:ok, %SlackConversationThread{} = slack_conversation_thread} =
               SlackConversationThreads.create_slack_conversation_thread(
                 slack_conversation_thread_attrs
               )

      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)

      assert_raise Ecto.NoResultsError, fn ->
        Conversations.get_conversation!(conversation.id)
      end

      assert_raise Ecto.NoResultsError, fn ->
        SlackConversationThreads.get_slack_conversation_thread!(slack_conversation_thread.id)
      end
    end

    test "change_conversation/1 returns a conversation changeset", %{conversation: conversation} do
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end

    test "has_agent_replied?/1 checks if an agent has replied to the conversation",
         %{account: account, customer: customer, conversation: conversation} do
      refute Conversations.has_agent_replied?(conversation.id)

      # Create a message from a customer (i.e. not an agent)
      insert(:message, account: account, customer: customer)
      refute Conversations.has_agent_replied?(conversation.id)

      # Create a message from an agent
      user = insert(:user, account: account)
      insert(:message, account: account, conversation: conversation, user: user)

      assert Conversations.has_agent_replied?(conversation.id)
    end

    test "archive_conversation/1 sets the archive_at field of a conversation",
         %{conversation: conversation} do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.archive_conversation(conversation)

      assert %DateTime{} = conversation.archived_at
    end

    test "query_conversations_closed_for/1 returns an Ecto.Query for conversations which have been closed for more than 14 days" do
      _closed_conversation = insert(:conversation, status: "closed")

      ready_to_archive_conversation =
        insert(:conversation, status: "closed", updated_at: days_ago(15))

      assert %Ecto.Query{} = query = Conversations.query_conversations_closed_for(days: 14)

      result_ids = query |> Repo.all() |> Enum.map(& &1.id)

      assert result_ids == [ready_to_archive_conversation.id]
    end

    test "query_free_tier_conversations_inactive_for/1 returns an Ecto.Query for free tier conversations that have been inactive for X days" do
      active_conversation = insert(:conversation, inserted_at: days_ago(31))
      insert(:message, conversation: active_conversation, inserted_at: days_ago(30))
      insert(:message, conversation: active_conversation, inserted_at: days_ago(20))
      insert(:message, conversation: active_conversation, inserted_at: days_ago(10))

      inactive_conversation = insert(:conversation, inserted_at: days_ago(35))
      insert(:message, conversation: inactive_conversation, inserted_at: days_ago(32))
      insert(:message, conversation: inactive_conversation, inserted_at: days_ago(31))
      insert(:message, conversation: inactive_conversation, inserted_at: days_ago(30))

      assert %Ecto.Query{} =
               query = Conversations.query_free_tier_conversations_inactive_for(days: 30)

      result_ids = query |> Repo.all() |> Enum.map(& &1.id)

      assert result_ids == [inactive_conversation.id]
    end

    test "archive_conversations/1 archives conversations which have been closed for more than 14 days" do
      past = DateTime.add(DateTime.utc_now(), -:timer.hours(336))

      closed_conversation = insert(:conversation, status: "closed")

      ready_to_archive_conversation = insert(:conversation, status: "closed", updated_at: past)

      assert {1, nil} =
               Conversations.query_conversations_closed_for(days: 14)
               |> Conversations.archive_conversations()

      archived_conversation = Conversations.get_conversation!(ready_to_archive_conversation.id)
      assert archived_conversation.archived_at

      closed_conversation = Conversations.get_conversation!(closed_conversation.id)
      refute closed_conversation.archived_at
    end

    test "archive_conversations/1 archives inactive free tier conversations" do
      conv1 = insert(:conversation, inserted_at: days_ago(31))
      insert(:message, conversation: conv1, inserted_at: days_ago(31))

      # just another conversation
      conv2 = insert(:conversation)
      insert(:message, conversation: conv2)

      conv1 = Conversations.get_conversation!(conv1.id)
      refute conv1.archived_at

      assert {1, _} =
               Conversations.query_free_tier_conversations_inactive_for(days: 30)
               |> Conversations.archive_conversations()

      conv1 = Conversations.get_conversation!(conv1.id)
      assert conv1.archived_at

      conv2 = Conversations.get_conversation!(conv2.id)
      refute conv2.archived_at
    end

    test "archive_conversations/1 does not archive free tier conversations with recently active message" do
      conv1 = insert(:conversation, inserted_at: days_ago(31))
      insert(:message, conversation: conv1, inserted_at: days_ago(3))

      # just another conversation
      conv2 = insert(:conversation)
      insert(:message, conversation: conv2)

      conv1 = Conversations.get_conversation!(conv1.id)
      refute conv1.archived_at

      assert {0, _} =
               Conversations.query_free_tier_conversations_inactive_for(days: 30)
               |> Conversations.archive_conversations()

      conv1 = Conversations.get_conversation!(conv1.id)
      refute conv1.archived_at

      conv2 = Conversations.get_conversation!(conv2.id)
      refute conv2.archived_at
    end

    test "update_conversation/2 sets the closed_at field based on updated status", %{
      conversation: conversation
    } do
      assert {:ok, %Conversation{} = closed_conversation} =
               Conversations.update_conversation(conversation, @update_attrs)

      assert %DateTime{} = closed_conversation.closed_at

      assert {:ok, %Conversation{} = open_conversation} =
               Conversations.update_conversation(conversation, %{status: "open"})

      assert open_conversation.closed_at == nil
    end

    test "get_first_message/1 returns the first message of the conversation",
         %{account: account, conversation: conversation} do
      refute Conversations.get_first_message(conversation.id)

      message =
        insert(:message,
          account: account,
          conversation: conversation,
          inserted_at: ~N[2020-11-02 20:00:00]
        )

      message_id = message.id

      assert %Message{id: ^message_id} = Conversations.get_first_message(conversation.id)
    end

    test "is_first_message?/2 checks if the message is the first message of the conversation",
         %{account: account, conversation: conversation} do
      first_message =
        insert(:message,
          account: account,
          conversation: conversation,
          inserted_at: ~N[2020-11-02 20:00:00]
        )

      second_message =
        insert(:message,
          account: account,
          conversation: conversation,
          inserted_at: ~N[2020-11-02 20:15:00]
        )

      assert Conversations.is_first_message?(conversation.id, first_message.id)
      refute Conversations.is_first_message?(conversation.id, second_message.id)
    end

    defp days_ago(days) do
      DateTime.utc_now()
      |> DateTime.add(days * 60 * 60 * 24 * -1)
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()
    end
  end
end
