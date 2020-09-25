defmodule ChatApi.MessagesTest do
  use ChatApi.DataCase, async: true

  alias ChatApi.Messages

  describe "messages" do
    alias ChatApi.Messages.Message

    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

    setup do
      account = account_fixture()
      customer = customer_fixture(account)
      conversation = conversation_fixture(account, customer)
      message = message_fixture(account, conversation, %{customer_id: customer.id})

      {:ok, message: message, account: account, customer: customer, conversation: conversation}
    end

    test "list_messages/1 returns all messages", %{message: message} do
      account_id = message.account_id
      messages = Messages.list_messages(account_id) |> Enum.map(fn msg -> msg.body end)

      assert messages == [message.body]
    end

    test "get_message!/1 returns the message with given id", %{message: message} do
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message", %{
      account: account,
      conversation: conversation
    } do
      attrs = %{
        body: "valid message body",
        conversation_id: conversation.id,
        account_id: account.id
      }

      assert {:ok, %Message{} = message} = Messages.create_message(attrs)
      assert message.body == attrs.body
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message", %{message: message} do
      assert {:ok, %Message{} = message} = Messages.update_message(message, @update_attrs)
      assert message.body == "some updated body"
    end

    test "update_message/2 with invalid data returns error changeset", %{message: message} do
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
      assert message == Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message", %{message: message} do
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset", %{message: message} do
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end

    test "get_message_type/1 returns the message sender type", %{
      account: account,
      conversation: conversation,
      customer: customer
    } do
      message = message_fixture(account, conversation, %{customer_id: customer.id})

      assert :customer = Messages.get_message_type(message)

      user = user_fixture(account)

      message = message_fixture(account, conversation, %{user_id: user.id})

      assert :agent = Messages.get_message_type(message)
    end

    test "get_conversation_topic/1 returns the conversation event topic", %{message: message} do
      %{conversation_id: conversation_id} = message
      topic = Messages.get_conversation_topic(message)

      assert "conversation:" <> ^conversation_id = topic
    end

    test "format/1 returns the formatted message", %{message: message, customer: customer} do
      assert %{body: body, customer: c} = Messages.format(message)
      assert body == message.body
      assert customer.email == c.email
    end
  end
end
