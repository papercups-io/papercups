defmodule ChatApi.MessagesTest do
  use ChatApi.DataCase

  alias ChatApi.{Messages, Conversations, Accounts}

  describe "messages" do
    alias ChatApi.Messages.Message

    @valid_attrs %{body: "some body"}
    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

    def valid_create_attrs do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      {:ok, conversation} =
        Conversations.create_conversation(%{status: "open", account_id: account.id})

      Enum.into(@valid_attrs, %{conversation_id: conversation.id, account_id: account.id})
    end

    def message_fixture(attrs \\ %{}) do
      {:ok, message} =
        attrs
        |> Enum.into(valid_create_attrs())
        |> Messages.create_message()

      Messages.get_message!(message.id)
    end

    test "list_messages/1 returns all messages" do
      message = message_fixture()
      account_id = message.account_id
      messages = Messages.list_messages(account_id) |> Enum.map(fn msg -> msg.body end)

      assert messages == [message.body]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Messages.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      assert {:ok, %Message{} = message} = Messages.create_message(valid_create_attrs())
      assert message.body == "some body"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messages.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      assert {:ok, %Message{} = message} = Messages.update_message(message, @update_attrs)
      assert message.body == "some updated body"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Messages.update_message(message, @invalid_attrs)
      assert message == Messages.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Messages.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Messages.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Messages.change_message(message)
    end
  end
end
