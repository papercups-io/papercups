defmodule ChatApiWeb.RoomChannel do
  use ChatApiWeb, :channel

  alias ChatApiWeb.Presence

  @impl true
  def join("room:" <> account_id, _params, socket) do
    send(self(), :after_join)

    {:ok, assign(socket, :account_id, account_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end
end
