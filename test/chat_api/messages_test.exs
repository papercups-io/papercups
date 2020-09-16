defmodule ChatApi.MessagesTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, Conversations, Customers, Messages}

  describe "messages" do
    alias ChatApi.Messages.Message
    alias ChatApi.Users.User

    @valid_attrs %{body: "some body"}
    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}
    @password "supersecretpassword"

    def valid_create_attrs do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      {:ok, conversation} =
        Conversations.create_conversation(%{status: "open", account_id: account.id})

      Enum.into(@valid_attrs, %{conversation_id: conversation.id, account_id: account.id})
    end

    def user_fixture(_attrs \\ %{}) do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      %User{}
      |> User.changeset(%{
        email: "test@example.com",
        password: @password,
        password_confirmation: @password,
        account_id: account.id
      })
      |> Repo.insert!()
    end

    def customer_fixture(attrs \\ %{}) do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})

      {:ok, customer} =
        attrs
        |> Enum.into(%{
          first_seen: ~D[2020-01-01],
          last_seen: ~D[2020-01-02],
          name: "Test User",
          email: "user@test.com",
          account_id: account.id
        })
        |> Customers.create_customer()

      Customers.get_customer!(customer.id)
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

    test "get_message_type/1 returns the message sender type" do
      customer = customer_fixture()
      message = message_fixture(%{customer_id: customer.id})

      assert :customer = Messages.get_message_type(message)

      user = user_fixture()
      message = message_fixture(%{user_id: user.id})

      assert :agent = Messages.get_message_type(message)
    end

    test "get_conversation_topic/1 returns the conversation event topic" do
      message = message_fixture()
      %{conversation_id: conversation_id} = message
      topic = Messages.get_conversation_topic(message)

      assert "conversation:" <> ^conversation_id = topic
    end

    test "format/1 returns the formatted message" do
      customer = customer_fixture()
      message = message_fixture(%{customer_id: customer.id})

      assert %{body: body, customer: c} = Messages.format(message)
      assert body == message.body
      assert customer.email == c.email
    end
  end
end
