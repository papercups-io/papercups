defmodule ChatApiWeb.EventChannel do
  use ChatApiWeb, :channel

  @impl true
  def join("events:" <> keys, _payload, socket) do
    case String.split(keys, ":") do
      [account_id, browser_session_id] ->
        {:ok,
         socket
         |> assign(:account_id, account_id)
         |> assign(:browser_session_id, browser_session_id)}

      _ ->
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
    enqueue_process_browser_replay_event(payload, socket)
    broadcast(socket, "replay:event:emitted", payload)
    {:noreply, socket}
  end

  defp enqueue_process_browser_replay_event(payload, socket) do
    case payload do
      %{"event" => event} ->
        %{
          "event" => event,
          "timestamp" => DateTime.from_unix!(event["timestamp"], :millisecond),
          "account_id" => socket.assigns.account_id,
          "browser_session_id" => socket.assigns.browser_session_id
        }
        |> ChatApi.Workers.SaveBrowserReplayEvent.new(max_attempts: 5)
        |> Oban.insert()

      _ ->
        nil
    end
  end
end
