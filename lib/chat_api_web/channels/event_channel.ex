defmodule ChatApiWeb.EventChannel do
  use ChatApiWeb, :channel

  @impl true
  def join("event:" <> _account_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client.
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic.
  @impl true
  def handle_in("replay:event:emitted", payload, socket) do
    # TODO: create session, connect to one channel, send data in
    # Then, as admin, connect to other channel, listen for data
    # Admin channel is secured
    # Broadcast events in realtime, but save in queue (in batches?)
    # `customer_id` is optional for now? Only apply it once known. Session ID is enough?
    broadcast(socket, "replay:event:emitted", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
