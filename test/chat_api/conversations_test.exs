defmodule ChatApi.ConversationsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.{Conversations, SlackConversationThreads}

  describe "conversations" do
    alias ChatApi.Conversations.Conversation
    alias ChatApi.SlackConversationThreads.SlackConversationThread

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

    test "get_conversation!/1 returns the conversation with given id",
         %{conversation: conversation} do
      found_conversation = Conversations.get_conversation!(conversation.id)

      assert found_conversation.id == conversation.id
    end

    test "create_conversation/1 with valid data creates a conversation" do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(params_with_assocs(:conversation))

      assert conversation.status == "open"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
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
      past = DateTime.add(DateTime.utc_now(), -:timer.hours(336))

      _closed_conversation = insert(:conversation, status: "closed")

      ready_to_archive_conversation =
        insert(:conversation,
          status: "closed",
          updated_at: past
        )

      assert %Ecto.Query{} = query = Conversations.query_conversations_closed_for(days: 14)

      result_ids = Enum.map(Repo.all(query), & &1.id)

      assert result_ids == [ready_to_archive_conversation.id]
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
  end
end
