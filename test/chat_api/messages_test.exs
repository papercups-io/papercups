defmodule ChatApi.MessagesTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Messages

  describe "messages" do
    alias ChatApi.Messages.Message

    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

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
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message",
         %{message: message} do
      assert {:ok, %Message{} = message} = Messages.update_message(message, @update_attrs)
      assert message.body == @update_attrs.body
    end

    test "update_message/2 with invalid data returns error changeset",
         %{message: message} do
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
    end

    test "delete_message/1 deletes the message", %{message: message} do
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset",
         %{message: message} do
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end

    test "get_message_type/1 returns the message sender type" do
      customer_message = insert(:message, user: nil)
      user_message = insert(:message, customer: nil)

      assert :customer = Messages.get_message_type(customer_message)
      assert :agent = Messages.get_message_type(user_message)
    end

    test "get_conversation_topic/1 returns the conversation event topic",
         %{message: message} do
      %{conversation_id: conversation_id} = message
      topic = Messages.get_conversation_topic(message)

      assert "conversation:" <> ^conversation_id = topic
    end

    test "format/1 returns the formatted message" do
      customer = insert(:customer)
      message = insert(:message, customer: customer)

      assert %{body: body, customer: c} = Messages.format(message)
      assert body == message.body
      assert customer.email == c.email
    end
  end
end
