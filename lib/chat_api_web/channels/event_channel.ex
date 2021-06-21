defmodule ChatApiWeb.EventChannel do
  use ChatApiWeb, :channel
  use Appsignal.Instrumentation.Decorators

  alias ChatApiWeb.Presence

  @impl true
  def join("events:admin:" <> keys, _payload, socket) do
    case String.split(keys, ":") do
      [account_id, "all"] ->
        if authorized?(socket, account_id) do
          send(self(), :after_join_admin_all)

          {:ok, socket |> assign(:account_id, account_id)}
        else
          {:error, %{reason: "unauthorized"}}
        end

      [account_id, browser_session_id] ->
        if authorized?(socket, account_id) do
          send(self(), :after_join_admin_session)

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
    case {String.split(keys, ":"), storytime_enabled?()} do
      # TODO: check that these IDs are valid (i.e. exist in DB)
      {[account_id, browser_session_id], true} ->
        send(self(), :after_join_customer_session)

        {:ok,
         socket
         |> assign(:account_id, account_id)
         |> assign(:browser_session_id, browser_session_id)}

      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join_admin_session, socket) do
    topic = get_customer_session_topic(socket)
    key = "session:" <> socket.assigns.browser_session_id

    # Track if an admin is watching so we know when to pipe events through
    {:ok, _} =
      Presence.track(self(), topic, key, %{
        online_at: inspect(System.system_time(:second)),
        account_id: socket.assigns.account_id,
        session_id: socket.assigns.browser_session_id,
        admin: true
      })

    ChatApiWeb.Endpoint.broadcast!(topic, "presence_state", Presence.list(topic))

    {:noreply, socket}
  end

  def handle_info(:after_join_admin_all, socket) do
    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  def handle_info(:after_join_customer_session, socket) do
    topic = get_admin_all_topic(socket)
    key = "session:" <> socket.assigns.browser_session_id

    # Add tracking to admin topic so we can track who is online
    {:ok, _} =
      Presence.track(self(), topic, key, %{
        online_at: inspect(System.system_time(:second)),
        account_id: socket.assigns.account_id,
        session_id: socket.assigns.browser_session_id,
        active: true,
        ts: DateTime.utc_now()
      })

    ChatApiWeb.Endpoint.broadcast!(topic, "presence_state", Presence.list(topic))

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client.
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @decorate channel_action()
  def handle_in("replay:event:emitted", payload, socket) do
    enqueue_process_browser_replay_event(payload, socket)
    broadcast_to_admin(socket, "replay:event:emitted", payload)

    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("session:active", _payload, socket) do
    topic = get_admin_all_topic(socket)
    key = "session:" <> socket.assigns.browser_session_id

    {:ok, _} =
      Presence.update(self(), topic, key, fn current ->
        Map.merge(current, %{active: true, ts: DateTime.utc_now()})
      end)

    ChatApiWeb.Endpoint.broadcast!(topic, "presence_state", Presence.list(topic))

    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("session:inactive", _payload, socket) do
    topic = get_admin_all_topic(socket)
    key = "session:" <> socket.assigns.browser_session_id

    {:ok, _} =
      Presence.update(self(), topic, key, fn current ->
        Map.merge(current, %{active: false, ts: DateTime.utc_now()})
      end)

    ChatApiWeb.Endpoint.broadcast!(topic, "presence_state", Presence.list(topic))

    {:noreply, socket}
  end

  defp get_admin_session_topic(socket) do
    [
      "events",
      "admin",
      socket.assigns.account_id,
      socket.assigns.browser_session_id
    ]
    |> Enum.join(":")
  end

  defp get_admin_all_topic(socket) do
    [
      "events",
      "admin",
      socket.assigns.account_id,
      "all"
    ]
    |> Enum.join(":")
  end

  defp get_customer_session_topic(socket) do
    [
      "events",
      socket.assigns.account_id,
      socket.assigns.browser_session_id
    ]
    |> Enum.join(":")
  end

  defp broadcast_to_admin(socket, event, payload) do
    socket
    |> get_admin_session_topic()
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

  defp storytime_enabled?() do
    case System.get_env("PAPERCUPS_STORYTIME_ENABLED", "true") do
      enabled when enabled == "1" or enabled == "true" -> true
      _ -> false
    end
  end

  defp authorized?(socket, account_id) do
    with %{current_user: current_user} <- socket.assigns,
         %{account_id: acct} <- current_user,
         true <- storytime_enabled?() do
      acct == account_id
    else
      _ -> false
    end
  end
end
