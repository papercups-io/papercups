defmodule ChatApiWeb.NotificationChannelTest do
  use ChatApiWeb.ChannelCase
  import ChatApi.Factory

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
end
