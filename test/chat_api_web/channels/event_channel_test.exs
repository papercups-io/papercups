defmodule ChatApiWeb.EventChannelTest do
  use ChatApiWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      ChatApiWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ChatApiWeb.EventChannel, "events:account:session")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to event:lobby", %{socket: socket} do
    push(socket, "replay:event:emitted", %{"hello" => "all"})
    # TODO: assert broadcast to admin channel
    # assert_broadcast "replay:event:emitted", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
