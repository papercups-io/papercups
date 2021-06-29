defmodule ChatApi.MessagesTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Messages
  alias ChatApi.Workers
  alias ChatApi.Messages.Message
  use Oban.Testing, repo: ChatApi.Repo

  describe "messages" do
    @update_attrs %{body: "some updated body"}

    setup do
      {:ok, message: insert(:message)}
    end

    test "list_messages/1 returns all messages", %{message: message} do
      account_id = message.account_id
      message_ids = Messages.list_messages(account_id) |> Enum.map(& &1.id)

      assert message_ids == [message.id]
    end

    test "get_message!/1 returns the message with given id",
         %{message: message} do
      assert Map.take(message, [:account_id, :conversation_id]) ==
               Messages.get_message!(message.id)
               |> Map.take([:account_id, :conversation_id])
    end

    test "create_message/1 with valid data creates a message" do
      attrs = params_with_assocs(:message, body: "valid message body")

      assert {:ok, %Message{} = message} = Messages.create_message(attrs)
      assert message.body == "valid message body"
      assert message.source == "chat"
    end

    test "create_message/1 queues a MessageCreatedActions job " do
      attrs = params_with_assocs(:message, body: "valid message body")

      assert {:ok, %Message{} = message} = Messages.create_message(attrs)

      assert_enqueued(worker: Workers.MessageCreatedActions, args: %{"id" => message.id})
    end

    test "create_message/1 with invalid source returns error changeset" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               Messages.create_message(%{body: "Hello world!", source: "unknown"})

      assert {"is invalid", _} = errors[:source]
    end

    test "update_message/2 with valid data updates the message",
         %{message: message} do
      assert {:ok, %Message{} = message} = Messages.update_message(message, @update_attrs)
      assert message.body == @update_attrs.body
    end

    test "delete_message/1 deletes the message", %{message: message} do
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset",
         %{message: message} do
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end

    test "list_by_conversation/3 returns messages by conversation" do
      account = insert(:account)
      conversation = insert(:conversation, account: account)

      a = insert(:message, conversation: conversation, account: account)

      b =
        insert(:message, conversation: conversation, account: account, private: true, type: "note")

      c = insert(:message, conversation: conversation, account: account)

      message_ids =
        conversation.id
        |> Messages.list_by_conversation()
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert message_ids == Enum.sort([a.id, b.id, c.id])
    end

    test "list_by_conversation/3 returns messages by conversation with filters" do
      account = insert(:account)
      conversation = insert(:conversation, account: account)

      a = insert(:message, conversation: conversation, account: account)

      _b =
        insert(:message, conversation: conversation, account: account, private: true, type: "note")

      c = insert(:message, conversation: conversation, account: account)

      message_ids =
        conversation.id
        |> Messages.list_by_conversation(%{"account_id" => account.id, "private" => false})
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert message_ids == Enum.sort([a.id, c.id])
    end

    test "list_by_conversation/3 returns messages by conversation with order/limit options" do
      account = insert(:account)
      conversation = insert(:conversation, account: account)

      a =
        insert(:message,
          conversation: conversation,
          account: account,
          inserted_at: ~N[2021-06-01 20:00:00]
        )

      _b =
        insert(:message,
          conversation: conversation,
          account: account,
          private: true,
          type: "note",
          inserted_at: ~N[2021-06-02 20:00:00]
        )

      _c =
        insert(:message,
          conversation: conversation,
          account: account,
          inserted_at: ~N[2021-06-03 20:00:00]
        )

      message_ids =
        conversation.id
        |> Messages.list_by_conversation(%{}, order_by: [asc: :inserted_at], limit: 1)
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert message_ids == [a.id]
    end
  end

  describe "helpers" do
    setup do
      {:ok, message: insert(:message)}
    end

    test "get_message_type/1 returns the message sender type" do
      customer_message = insert(:message, user: nil)
      user_message = insert(:message, customer: nil)

      assert :customer = Messages.Helpers.get_message_type(customer_message)
      assert :agent = Messages.Helpers.get_message_type(user_message)
    end

    test "get_conversation_topic/1 returns the conversation event topic",
         %{message: message} do
      %{conversation_id: conversation_id} = message
      topic = Messages.Helpers.get_conversation_topic(message)

      assert "conversation:" <> ^conversation_id = topic
    end

    test "format/1 returns the formatted message" do
      customer = insert(:customer)
      message = insert(:message, customer: customer)

      assert %{body: body, customer: c} = Messages.Helpers.format(message)
      assert body == message.body
      assert customer.email == c.email
    end

    test "build_conversation_updates/1 builds the conversation updates for a created message" do
      account = insert(:account)
      agent = insert(:user, account: account)
      customer = insert(:customer, account: account)
      conversation = insert(:conversation, account: account, customer: customer)

      initial_customer_message =
        insert(:message, conversation: conversation, customer: customer, user: nil)

      # No conversation updates are necessary on the first customer message
      assert %{read: false} =
               Messages.Helpers.build_conversation_updates(initial_customer_message)

      first_agent_reply = insert(:message, conversation: conversation, user: agent, customer: nil)
      agent_id = agent.id

      # After the first reply, auto-assign the responder and mark the conversation as "read"
      assert %{assignee_id: ^agent_id, read: true} =
               Messages.Helpers.build_conversation_updates(first_agent_reply)

      first_customer_reply =
        insert(:message, conversation: conversation, customer: customer, user: nil)

      assert %{read: false} = Messages.Helpers.build_conversation_updates(first_customer_reply)

      second_agent_reply =
        insert(:message, conversation: conversation, user: agent, customer: nil)

      # On subsequent replies, just mark the conversation as "read"
      assert %{read: true} = Messages.Helpers.build_conversation_updates(second_agent_reply)

      second_customer_reply =
        insert(:message, conversation: conversation, customer: customer, user: nil)

      assert %{} = Messages.Helpers.build_conversation_updates(second_customer_reply)
    end
  end
end
