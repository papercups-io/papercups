defmodule ChatApiWeb.BrowserReplayEventView do
  use ChatApiWeb, :view
  alias ChatApiWeb.BrowserReplayEventView

  def render("index.json", %{browser_replay_events: browser_replay_events}) do
    %{
      data:
        render_many(browser_replay_events, BrowserReplayEventView, "browser_replay_event.json")
    }
  end

  def render("show.json", %{browser_replay_event: browser_replay_event}) do
    %{data: render_one(browser_replay_event, BrowserReplayEventView, "browser_replay_event.json")}
  end

  def render("browser_replay_event.json", %{browser_replay_event: browser_replay_event}) do
    %{
      id: browser_replay_event.id,
      object: "browser_replay_event",
      account_id: browser_replay_event.account_id,
      event: browser_replay_event.event,
      timestamp: browser_replay_event.timestamp
    }
  end
end
