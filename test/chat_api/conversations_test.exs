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

      Enum.into(@valid_attrs, %{account_id: account.id})
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

    test "find_by_customer/2 returns all not archived conversations for a customer", %{
      account: account,
      conversation: conversation,
      customer: customer
    } do
      _archived_conversation =
        conversation_fixture(account, customer) |> Conversations.archive_conversation()

      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
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

      assert conversation = Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation", %{conversation: conversation} do
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "delete_conversation/1 deletes the conversation if associated slack_conversation_threads exist",
         %{conversation: conversation} do
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

    test "archive_conversation/1 sets the archive_at field of a conversation", %{
      conversation: conversation
    } do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.archive_conversation(conversation)

      assert %DateTime{} = conversation.archived_at
    end
  end
end
