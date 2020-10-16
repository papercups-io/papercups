defmodule ChatApiWeb.EventChannel do
  use ChatApiWeb, :channel

  @impl true
  def join("events:admin:" <> keys, _payload, socket) do
    case String.split(keys, ":") do
      [account_id, browser_session_id] ->
        if authorized?(socket, account_id) do
          send(self(), :after_join)

          {:ok,
           socket
           |> assign(:account_id, account_id)
           |> assign(:browser_session_id, browser_session_id)}
        else
          {:error, %{reason: "unauthorized"}}
        end

      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

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

  @impl true
  def handle_info(:after_join, socket) do
    broadcast_to_session(socket, "admin:watching")

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client.
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("replay:event:emitted", payload, socket) do
    enqueue_process_browser_replay_event(payload, socket)
    broadcast_to_admin(socket, "replay:event:emitted", payload)

    {:noreply, socket}
  end

  defp broadcast_to_session(socket, event, payload \\ %{}) do
    [
      "events",
      socket.assigns.account_id,
      socket.assigns.browser_session_id
    ]
    |> Enum.join(":")
    |> ChatApiWeb.Endpoint.broadcast!(event, payload)
  end

  defp broadcast_to_admin(socket, event, payload) do
    [
      "events",
      "admin",
      socket.assigns.account_id,
      socket.assigns.browser_session_id
    ]
    |> Enum.join(":")
    |> ChatApiWeb.Endpoint.broadcast!(event, payload)
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

  defp authorized?(socket, account_id) do
    with %{current_user: current_user} <- socket.assigns,
         %{account_id: acct} <- current_user do
      acct == account_id
    else
      _ -> false
    end
  end
end
