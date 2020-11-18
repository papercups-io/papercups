defmodule ChatApi.ConversationsTest do
  use ChatApi.DataCase, async: true

  alias ChatApi.{Conversations, SlackConversationThreads}

  describe "conversations" do
    alias ChatApi.Conversations.Conversation
    alias ChatApi.SlackConversationThreads.SlackConversationThread

    @valid_attrs %{status: "open"}
    @update_attrs %{status: "closed"}
    @invalid_attrs %{status: nil}

    def valid_create_attrs do
      account = account_fixture()
      customer = customer_fixture(account)

      Enum.into(@valid_attrs, %{account_id: account.id, customer_id: customer.id})
    end

    setup do
      account = account_fixture()
      customer = customer_fixture(account)
      conversation = conversation_fixture(account, customer)

      {:ok, account: account, conversation: conversation, customer: customer}
    end

    test "list_conversations/0 returns all conversations", %{
      conversation: conversation
    } do
      result_ids = Enum.map(Conversations.list_conversations(), fn r -> r.id end)

      assert result_ids == [conversation.id]
    end

    test "list_conversations_by_account/1 returns all conversations for an account", %{
      account: account,
      conversation: conversation
    } do
      different_account = account_fixture()
      different_customer = customer_fixture(different_account)
      _conversation = conversation_fixture(different_account, different_customer)

      result_ids = Enum.map(Conversations.list_conversations_by_account(account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "list_conversations_by_account/1 returns all not archived conversations for an account",
         %{
           account: account,
           conversation: conversation,
           customer: customer
         } do
      _archived_conversation =
        conversation_fixture(account, customer) |> Conversations.archive_conversation()

      result_ids = Enum.map(Conversations.list_conversations_by_account(account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "find_by_customer/2 returns all conversations for a customer", %{
      account: account,
      conversation: conversation,
      customer: customer
    } do
      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "find_by_customer/2 does not include archived conversations for a customer", %{
      account: account,
      conversation: conversation,
      customer: customer
    } do
      _archived_conversation =
        conversation_fixture(account, customer) |> Conversations.archive_conversation()

      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "find_by_customer/2 does not include closed conversations for a customer", %{
      account: account,
      customer: customer
    } do
      closed = conversation_fixture(account, customer, %{status: "closed"})
      results = Conversations.find_by_customer(customer.id, account.id)
      ids = Enum.map(results, & &1.id)

      refute Enum.member?(ids, closed.id)
      assert Enum.all?(results, fn conv -> conv.status == "open" end)
    end

    test "get_conversation!/1 returns the conversation with given id", %{
      conversation: conversation
    } do
      assert Conversations.get_conversation!(conversation.id) == conversation
    end

    test "create_conversation/1 with valid data creates a conversation" do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(valid_create_attrs())

      assert conversation.status == "open"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "update_conversation/2 with valid data updates the conversation", %{
      conversation: conversation
    } do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.update_conversation(conversation, @update_attrs)

      assert conversation.status == "closed"
    end

    test "update_conversation/2 with invalid data returns error changeset", %{
      conversation: conversation
    } do
      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation(conversation, @invalid_attrs)

      assert _conversation = Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation", %{conversation: conversation} do
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "delete_conversation/1 deletes the conversation if associated slack_conversation_threads exist",
         %{conversation: _conversation} do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(valid_create_attrs())

      slack_conversation_thread_attrs = %{
        slack_channel: "some slack_channel",
        slack_thread_ts: "some slack_thread_ts",
        conversation_id: conversation.id,
        account_id: valid_create_attrs().account_id
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

    test "has_agent_replied?/1 checks if an agent has replied to the conversation", %{
      account: account,
      customer: customer,
      conversation: conversation
    } do
      refute Conversations.has_agent_replied?(conversation.id)

      # Create a message from a customer (i.e. not an agent)
      message_fixture(account, conversation, %{customer_id: customer.id})

      refute Conversations.has_agent_replied?(conversation.id)

      # Create a message from an agent
      user = user_fixture(account)
      message_fixture(account, conversation, %{user_id: user.id})

      assert Conversations.has_agent_replied?(conversation.id)
    end

    test "archive_conversation/1 sets the archive_at field of a conversation", %{
      conversation: conversation
    } do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.archive_conversation(conversation)

      assert %DateTime{} = conversation.archived_at
    end

    test "query_conversations_closed_for/1 returns an Ecto.Query for conversations which have been closed for more than 14 days",
         %{conversation: _conversation, account: account, customer: customer} do
      past = DateTime.add(DateTime.utc_now(), -(14 * 24 * 60 * 60))

      _closed_conversation =
        conversation_fixture(account, customer, %{
          updated_at: DateTime.utc_now(),
          status: "closed"
        })

      ready_to_archive_conversation =
        conversation_fixture(account, customer, %{updated_at: past, status: "closed"})

      assert %Ecto.Query{} = query = Conversations.query_conversations_closed_for(days: 14)

      result_ids = Enum.map(Repo.all(query), & &1.id)

      assert result_ids == [ready_to_archive_conversation.id]
    end

    test "archive_conversations/1 archives conversations which have been closed for more than 14 days",
         %{conversation: _conversation, account: account, customer: customer} do
      past = DateTime.add(DateTime.utc_now(), -(14 * 24 * 60 * 60))

      closed_conversation =
        conversation_fixture(account, customer, %{
          updated_at: DateTime.utc_now(),
          status: "closed"
        })

      ready_to_archive_conversation =
        conversation_fixture(account, customer, %{updated_at: past, status: "closed"})

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
