defmodule ChatApi.ConversationsTest do
  use ChatApi.DataCase

  alias ChatApi.Conversations
  alias ChatApi.Messages
  alias ChatApi.Accounts

  describe "conversations" do
    alias ChatApi.Conversations.Conversation

    @valid_attrs %{status: "open"}
    @update_attrs %{status: "closed"}
    @invalid_attrs %{status: nil}

    def valid_create_attrs do
      account = account_fixture()

      Enum.into(@valid_attrs, %{account_id: account.id})
    end

    def account_fixture do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})
      account
    end

    def conversation_fixture(attrs \\ %{}) do
      {:ok, conversation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Conversations.create_conversation()

      {:ok, _message} =
        Messages.create_message(%{
          body: "Test message",
          conversation_id: conversation.id,
          account_id: conversation.account_id
        })

      Conversations.get_conversation!(conversation.id)
    end

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_conversations/0 returns all conversations", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})
      result_ids = Enum.map(Conversations.list_conversations(), fn r -> r.id end)

      assert result_ids == [conversation.id]
    end

    test "list_conversations_by_account/1 returns all conversations for an account", %{
      account: account
    } do
      different_account = account_fixture()
      conversation = conversation_fixture(%{account_id: account.id})
      _conversation = conversation_fixture(%{account_id: different_account.id})

      result_ids =
        Enum.map(Conversations.list_conversations_by_account(account.id), fn r -> r.id end)

      assert result_ids == [conversation.id]
    end

    test "get_conversation!/1 returns the conversation with given id", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})
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

    test "update_conversation/2 with valid data updates the conversation", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})

      assert {:ok, %Conversation{} = conversation} =
               Conversations.update_conversation(conversation, @update_attrs)

      assert conversation.status == "closed"
    end

    test "update_conversation/2 with invalid data returns error changeset", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})

      assert {:error, %Ecto.Changeset{}} =
               Conversations.update_conversation(conversation, @invalid_attrs)

      assert conversation == Conversations.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "change_conversation/1 returns a conversation changeset", %{account: account} do
      conversation = conversation_fixture(%{account_id: account.id})
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end
  end
end
