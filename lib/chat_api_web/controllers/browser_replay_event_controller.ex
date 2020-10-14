defmodule ChatApiWeb.BrowserReplayEventController do
  use ChatApiWeb, :controller

  alias ChatApi.BrowserReplayEvents
  alias ChatApi.BrowserReplayEvents.BrowserReplayEvent

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      browser_replay_events = BrowserReplayEvents.list_browser_replay_events(account_id)
      render(conn, "index.json", browser_replay_events: browser_replay_events)
    end
  end

  def show(conn, %{"id" => id}) do
    browser_replay_event = BrowserReplayEvents.get_browser_replay_event!(id)
    render(conn, "show.json", browser_replay_event: browser_replay_event)
  end

  def delete(conn, %{"id" => id}) do
    browser_replay_event = BrowserReplayEvents.get_browser_replay_event!(id)

    with {:ok, %BrowserReplayEvent{}} <-
           BrowserReplayEvents.delete_browser_replay_event(browser_replay_event) do
      send_resp(conn, :no_content, "")
    end
  end
end
