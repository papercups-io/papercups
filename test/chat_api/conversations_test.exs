defmodule ChatApi.ConversationsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory

  alias ChatApi.Repo
  alias ChatApi.{Conversations, SlackConversationThreads}
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

  describe "list_conversations_by_account/1" do
    test "returns all conversations for an account",
         %{account: account, conversation: conversation} do
      result_ids = Enum.map(Conversations.list_conversations_by_account(account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "sorts the conversations by most recent message",
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

    test "returns all not archived conversations for an account",
         %{account: account, conversation: conversation} do
      not_archived_conversation = insert(:conversation, account: account)
      _archived_conversation = Conversations.archive_conversation(conversation)

      result_ids = Enum.map(Conversations.list_conversations_by_account(account.id), & &1.id)

      assert result_ids == [not_archived_conversation.id]
    end

    test "filters conversations for an account by tag", %{
      account: account,
      conversation: conversation
    } do
      tag = insert(:tag)
      Conversations.add_tag(conversation, tag.id)

      result_ids =
        account.id
        |> Conversations.list_conversations_by_account(%{"tag_id" => tag.id})
        |> Enum.map(& &1.id)

      assert result_ids == [conversation.id]

      Conversations.remove_tag(conversation, tag.id)

      assert [] = Conversations.list_conversations_by_account(account.id, %{"tag_id" => tag.id})
    end
  end

  describe "find_by_customer/2" do
    test "returns all conversations for a customer",
         %{account: account, conversation: conversation, customer: customer} do
      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "does not include archived conversations for a customer",
         %{account: account, conversation: conversation, customer: customer} do
      _archived_conversation =
        insert(:conversation, account: account, customer: customer)
        |> Conversations.archive_conversation()

      result_ids = Enum.map(Conversations.find_by_customer(customer.id, account.id), & &1.id)

      assert result_ids == [conversation.id]
    end

    test "does not include closed conversations for a customer",
         %{account: account, customer: customer} do
      closed = insert(:conversation, account: account, customer: customer, status: "closed")

      results = Conversations.find_by_customer(customer.id, account.id)
      ids = Enum.map(results, & &1.id)

      refute Enum.member?(ids, closed.id)
      assert Enum.all?(results, fn conv -> conv.status == "open" end)
    end

    test "does not include private messages in the conversation results",
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
  end

  describe "get_conversation!/1" do
    test "returns the conversation with given id",
         %{conversation: conversation} do
      found_conversation = Conversations.get_conversation!(conversation.id)

      assert found_conversation.id == conversation.id
    end
  end

  describe "create_conversation/1" do
    test "with valid data creates a conversation" do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(params_with_assocs(:conversation))

      assert conversation.status == "open"
      assert conversation.source == "chat"
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "with invalid source returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               Conversations.create_conversation(%{status: "closed", source: "unknown"})

      assert {"is invalid", _} = errors[:source]
    end
  end

  describe "update_conversation/2" do
    test "with valid data updates the conversation",
         %{conversation: conversation} do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.update_conversation(conversation, @update_attrs)

      assert conversation.status == "closed"
    end

    test "with invalid data returns error changeset",
         %{conversation: conversation} do
      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation(conversation, @invalid_attrs)

      assert _conversation = Conversations.get_conversation!(conversation.id)
    end

    test "sets the closed_at field based on updated status", %{
      conversation: conversation
    } do
      assert {:ok, %Conversation{} = closed_conversation} =
               Conversations.update_conversation(conversation, @update_attrs)

      assert %DateTime{} = closed_conversation.closed_at

      assert {:ok, %Conversation{} = open_conversation} =
               Conversations.update_conversation(conversation, %{status: "open"})

      assert open_conversation.closed_at == nil
    end
  end

  describe "delete_conversation/1" do
    test "deletes the conversation",
         %{conversation: conversation} do
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "deletes the conversation if associated slack_conversation_threads exist" do
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
  end

  describe "change_conversation/1" do
    test "returns a conversation changeset", %{conversation: conversation} do
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end
  end

  describe "has_agent_replied?/1" do
    test "checks if an agent has replied to the conversation",
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
  end

  describe "archive_conversation/1" do
    test "sets the archive_at field of a conversation",
         %{conversation: conversation} do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.archive_conversation(conversation)

      assert %DateTime{} = conversation.archived_at
    end
  end

  describe "query_conversations_closed_for/1" do
    test "returns an Ecto.Query for conversations which have been closed for more than 14 days" do
      _closed_conversation = insert(:conversation, status: "closed")

      ready_to_archive_conversation =
        insert(:conversation, status: "closed", updated_at: days_ago(15))

      assert %Ecto.Query{} = query = Conversations.query_conversations_closed_for(days: 14)

      result_ids = query |> Repo.all() |> Enum.map(& &1.id)

      assert result_ids == [ready_to_archive_conversation.id]
    end
  end

  describe "query_free_tier_conversations_inactive_for/1" do
    test "returns an Ecto.Query for free tier conversations that have been inactive for X days" do
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
  end

  describe "archive_conversations/1" do
    test "archives conversations which have been closed for more than 14 days" do
      past = DateTime.add(DateTime.utc_now(), -:timer.hours(336), :millisecond)

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

    test "archives inactive free tier conversations" do
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

    test "does not archive free tier conversations with recently active message" do
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
  end

  describe "get_first_message/1" do
    test "returns the first message of the conversation",
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
  end

  describe "is_first_message?/2" do
    test "checks if the message is the first message of the conversation",
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
  end

  describe "get_previous_conversation/2" do
    test "gets the previous conversation from the same customer if one exists",
         %{account: account, conversation: conversation, customer: customer} do
      refute Conversations.get_previous_conversation(conversation)

      previous_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-12-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-02 20:00:00]
      )

      assert Conversations.get_previous_conversation(conversation) |> Map.get(:id) ==
               previous_conversation.id

      refute Conversations.get_previous_conversation(previous_conversation)

      earlier_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-11-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-02 20:00:00]
      )

      # Assert that this hasn't changed
      assert Conversations.get_previous_conversation(conversation) |> Map.get(:id) ==
               previous_conversation.id

      assert Conversations.get_previous_conversation(previous_conversation) |> Map.get(:id) ==
               earlier_conversation.id
    end

    test "gets the previous conversation based on message activity",
         %{account: account, conversation: conversation, customer: customer} do
      previous_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-12-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-02 20:00:00]
      )

      earlier_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-11-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-02 20:00:00]
      )

      assert Conversations.get_previous_conversation(conversation) |> Map.get(:id) ==
               previous_conversation.id

      # Create a new message in the earlier conversation for right now, making it more recently active
      insert(:message,
        account: account,
        conversation: earlier_conversation
      )

      assert Conversations.get_previous_conversation(conversation) |> Map.get(:id) ==
               earlier_conversation.id
    end
  end

  describe "get_previous_conversation_id/2" do
    test "gets the previous conversation from the same customer if one exists",
         %{account: account, conversation: conversation, customer: customer} do
      refute Conversations.get_previous_conversation_id(conversation)

      previous_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-12-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-02 20:00:00]
      )

      assert Conversations.get_previous_conversation_id(conversation) ==
               previous_conversation.id

      refute Conversations.get_previous_conversation_id(previous_conversation)

      earlier_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-11-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-02 20:00:00]
      )

      # Assert that this hasn't changed
      assert Conversations.get_previous_conversation_id(conversation) ==
               previous_conversation.id

      assert Conversations.get_previous_conversation_id(previous_conversation) ==
               earlier_conversation.id
    end

    test "gets the previous conversation based on message activity",
         %{account: account, conversation: conversation, customer: customer} do
      previous_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-12-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-02 20:00:00]
      )

      earlier_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-11-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-02 20:00:00]
      )

      assert Conversations.get_previous_conversation_id(conversation) ==
               previous_conversation.id

      # Create a new message in the earlier conversation for right now, making it more recently active
      insert(:message,
        account: account,
        conversation: earlier_conversation
      )

      assert Conversations.get_previous_conversation_id(conversation) ==
               earlier_conversation.id
    end
  end

  describe "list_other_recent_conversations/2" do
    test "gets other recent conversations related to the conversation customer",
         %{account: account, conversation: conversation, customer: customer} do
      latest_conversation_id = conversation.id

      %Conversation{id: previous_conversation_id} =
        previous_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-12-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-02 20:00:00]
      )

      %Conversation{id: earlier_conversation_id} =
        earlier_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-11-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-02 20:00:00]
      )

      # Verify that the results are sorted from most recent to least
      assert [
               %Conversation{id: ^previous_conversation_id},
               %Conversation{id: ^earlier_conversation_id}
             ] = Conversations.list_other_recent_conversations(conversation)

      assert [
               %Conversation{id: ^latest_conversation_id},
               %Conversation{id: ^earlier_conversation_id}
             ] = Conversations.list_other_recent_conversations(previous_conversation)

      assert [
               %Conversation{id: ^latest_conversation_id},
               %Conversation{id: ^previous_conversation_id}
             ] = Conversations.list_other_recent_conversations(earlier_conversation)

      # Verify that the `limit` param works
      assert [
               %Conversation{id: ^previous_conversation_id}
             ] = Conversations.list_other_recent_conversations(conversation, 1)

      assert [
               %Conversation{id: ^latest_conversation_id}
             ] = Conversations.list_other_recent_conversations(previous_conversation, 1)
    end

    test "handles no other recent conversations", %{
      conversation: conversation
    } do
      assert [] = Conversations.list_other_recent_conversations(conversation)
    end
  end

  describe "list_recent_by_customer/3" do
    test "gets recently active conversations for the given customer",
         %{account: account, conversation: conversation, customer: customer} do
      latest_conversation_id = conversation.id

      insert(:message,
        account: account,
        conversation: conversation,
        body: "Latest message"
      )

      %Conversation{id: previous_conversation_id} =
        previous_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-12-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-01 20:00:00],
        body: "Previous conversation message #1"
      )

      insert(:message,
        account: account,
        conversation: previous_conversation,
        inserted_at: ~N[2020-12-02 20:00:00],
        body: "Previous conversation message #2"
      )

      %Conversation{id: earlier_conversation_id} =
        earlier_conversation =
        insert(:conversation,
          account: account,
          customer: customer,
          inserted_at: ~N[2020-11-01 20:00:00]
        )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-01 20:00:00],
        body: "Earlier conversation message #1"
      )

      insert(:message,
        account: account,
        conversation: earlier_conversation,
        inserted_at: ~N[2020-11-02 20:00:00],
        body: "Earlier conversation message #2"
      )

      # Verify that the results are sorted from most recent to least, and only include the latest message
      assert [
               %Conversation{
                 id: ^latest_conversation_id,
                 messages: [%Message{body: "Latest message"}]
               },
               %Conversation{
                 id: ^previous_conversation_id,
                 messages: [%Message{body: "Previous conversation message #2"}]
               },
               %Conversation{
                 id: ^earlier_conversation_id,
                 messages: [%Message{body: "Earlier conversation message #2"}]
               }
             ] = Conversations.list_recent_by_customer(customer.id, account.id)
    end

    test "handles no recent conversations", %{account: account} do
      new_customer = insert(:customer, account: account)

      assert [] = Conversations.list_recent_by_customer(new_customer.id, account.id)
    end
  end

  describe "list_conversations_by_account_paginated/1" do
    test "sorts the conversations by most recent activity" do
      account = insert(:account)
      pagination_options = [limit: 5]
      base_last_activity_at = DateTime.from_naive!(~N[2020-12-01 00:00:00], "Etc/UTC")

      [first_batch, second_batch, third_batch] =
        15..1
        |> Enum.map(
          &insert(:conversation,
            account: account,
            last_activity_at: DateTime.add(base_last_activity_at, &1 * 3600, :second)
          )
        )
        |> Enum.chunk_every(5)

      %{metadata: metadata1, entries: entries1} =
        Conversations.list_conversations_by_account_paginated(account.id, %{}, pagination_options)

      assert Enum.map(entries1, & &1.id) == Enum.map(first_batch, & &1.id)

      %{metadata: metadata2, entries: entries2} =
        Conversations.list_conversations_by_account_paginated(
          account.id,
          %{},
          Keyword.merge(pagination_options, after: metadata1.after)
        )

      assert Enum.map(entries2, & &1.id) == Enum.map(second_batch, & &1.id)

      %{metadata: metadata3, entries: entries3} =
        Conversations.list_conversations_by_account_paginated(
          account.id,
          %{},
          Keyword.merge(pagination_options, after: metadata2.after)
        )

      assert Enum.map(entries3, & &1.id) == Enum.map(third_batch, & &1.id)

      assert metadata3.after == nil
    end
  end

  defp days_ago(days) do
    DateTime.utc_now()
    |> DateTime.add(days * 60 * 60 * 24 * -1)
    |> DateTime.truncate(:second)
    |> DateTime.to_naive()
  end
end
