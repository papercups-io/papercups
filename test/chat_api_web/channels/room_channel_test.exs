defmodule ChatApiWeb.RoomChannelTest do
  use ChatApiWeb.ChannelCase

  @account_id "123"

  setup do
    {:ok, _, socket} =
      ChatApiWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(ChatApiWeb.RoomChannel, "room:" <> @account_id)

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    assert @account_id = socket.assigns.account_id
  end
end
