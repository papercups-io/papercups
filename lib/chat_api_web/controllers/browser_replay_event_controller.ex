defmodule ChatApiWeb.BrowserReplayEventController do
  use ChatApiWeb, :controller

  alias ChatApi.BrowserReplayEvents
  alias ChatApi.BrowserReplayEvents.BrowserReplayEvent

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    browser_replay_events = BrowserReplayEvents.list_browser_replay_events()
    render(conn, "index.json", browser_replay_events: browser_replay_events)
  end

  def create(conn, %{"browser_replay_event" => browser_replay_event_params}) do
    with {:ok, %BrowserReplayEvent{} = browser_replay_event} <-
           BrowserReplayEvents.create_browser_replay_event(browser_replay_event_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.browser_replay_event_path(conn, :show, browser_replay_event)
      )
      |> render("show.json", browser_replay_event: browser_replay_event)
    end
  end

  def show(conn, %{"id" => id}) do
    browser_replay_event = BrowserReplayEvents.get_browser_replay_event!(id)
    render(conn, "show.json", browser_replay_event: browser_replay_event)
  end

  def update(conn, %{"id" => id, "browser_replay_event" => browser_replay_event_params}) do
    browser_replay_event = BrowserReplayEvents.get_browser_replay_event!(id)

    with {:ok, %BrowserReplayEvent{} = browser_replay_event} <-
           BrowserReplayEvents.update_browser_replay_event(
             browser_replay_event,
             browser_replay_event_params
           ) do
      render(conn, "show.json", browser_replay_event: browser_replay_event)
    end
  end

  def delete(conn, %{"id" => id}) do
    browser_replay_event = BrowserReplayEvents.get_browser_replay_event!(id)

    with {:ok, %BrowserReplayEvent{}} <-
           BrowserReplayEvents.delete_browser_replay_event(browser_replay_event) do
      send_resp(conn, :no_content, "")
    end
  end
end
