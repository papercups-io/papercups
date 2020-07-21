defmodule ChatApiWeb.NotificationChannelTest do
  use ChatApiWeb.ChannelCase

  alias ChatApi.{Accounts, Conversations}

  setup do
    {:ok, account} = Accounts.create_account(%{company_name: "Taro"})

    {:ok, conversation} =
      Conversations.create_conversation(%{account_id: account.id, status: "open"})

    {:ok, _, socket} =
      ChatApiWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ChatApiWeb.NotificationChannel, "notification:lobby")

    %{socket: socket, account: account, conversation: conversation}
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
    msg = %{body: "Hello world!", account_id: account.id, conversation_id: conversation.id}
    push(socket, "shout", msg)

    assert_push("shout", msg)
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
