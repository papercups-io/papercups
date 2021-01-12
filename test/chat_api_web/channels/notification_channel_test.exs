defmodule ChatApiWeb.NotificationChannelTest do
  use ChatApiWeb.ChannelCase
  import ChatApi.Factory

  alias ChatApi.Conversations
  alias ChatApi.Conversations.Conversation

  setup do
    account = insert(:account)
    user = insert(:user, account: account)
    conversation = insert(:conversation, account: account)

    {:ok, _, socket} =
      ChatApiWeb.UserSocket
      |> socket("user_id", %{current_user: user})
      |> subscribe_and_join(ChatApiWeb.NotificationChannel, "notification:" <> account.id, %{
        "ids" => [conversation.id]
      })

    %{socket: socket, account: account, conversation: conversation, user: user}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to notification:lobby", %{
    socket: socket,
    account: account,
    conversation: conversation
  } do
    msg = %{
      body: "Hello world!",
      account_id: account.id,
      conversation_id: conversation.id
    }

    push(socket, "shout", msg)

    assert_push("shout", _msg)
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end

  describe "Auto-assigning first responder" do
    test "conversation assignee is updated when first agent replies", %{
      socket: socket,
      account: account,
      user: user,
      conversation: conversation
    } do
      msg = %{
        body: "Hello world!",
        account_id: account.id,
        conversation_id: conversation.id
      }

      ref = push(socket, "shout", msg)
      assert_reply(ref, :ok)
      user_id = user.id

      assert %Conversation{assignee_id: ^user_id} =
               Conversations.get_conversation(conversation.id)
    end

    test "conversation assignee is not updated on subsequent replies", %{
      socket: socket,
      account: account,
      user: user,
      conversation: conversation
    } do
      msg = %{
        body: "Hello world!",
        account_id: account.id,
        conversation_id: conversation.id
      }

      # First reply message
      ref = push(socket, "shout", msg)
      assert_reply(ref, :ok)

      other_agent = insert(:user, account: account)

      {:ok, _, other_socket} =
        ChatApiWeb.UserSocket
        |> socket("user_id", %{current_user: other_agent})
        |> subscribe_and_join(ChatApiWeb.NotificationChannel, "notification:" <> account.id, %{
          "ids" => [conversation.id]
        })

      # Second reply message
      other_ref = push(other_socket, "shout", msg)
      assert_reply(other_ref, :ok)

      assert %Conversation{assignee_id: assignee_id} =
               Conversations.get_conversation(conversation.id)

      assert assignee_id != other_agent.id
      assert assignee_id == user.id
    end
  end

  describe "Updating first replied at" do
    test "conversation first replied at is updated", %{
      socket: socket,
      account: account,
      conversation: conversation
    } do
      inserted_at = DateTime.utc_now()

      msg = %{
        body: "Hello world!",
        account_id: account.id,
        conversation_id: conversation.id,
        inserted_at: inserted_at
      }

      ref = push(socket, "shout", msg)
      assert_reply(ref, :ok)
      conv = Conversations.get_conversation(conversation.id)

      assert conv.first_replied_at == DateTime.truncate(inserted_at, :second)
    end

    test "it only happens on first reply", %{
      socket: socket,
      account: account,
      conversation: conversation
    } do
      inserted_at = DateTime.utc_now()

      msg = %{
        body: "Hello world!",
        account_id: account.id,
        conversation_id: conversation.id
      }

      response = %{
        body: "goodbye world",
        account_id: account.id,
        conversation_id: conversation.id
      }

      initial_reply_ref = push(socket, "shout", msg)
      assert_reply(initial_reply_ref, :ok)

      conv = Conversations.get_conversation(conversation.id)

      assert conv.first_replied_at == DateTime.truncate(inserted_at, :second)

      Process.sleep(1000)

      next_reply_ref = push(socket, "shout", response)
      assert_reply(next_reply_ref, :ok)

      conv = Conversations.get_conversation(conversation.id)

      assert conv.first_replied_at == DateTime.truncate(inserted_at, :second)
    end
  end
end
