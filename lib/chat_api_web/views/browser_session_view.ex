defmodule ChatApiWeb.BrowserSessionView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{BrowserSessionView, BrowserReplayEventView, CustomerView}

  def render("index.json", %{browser_sessions: browser_sessions}) do
    %{data: render_many(browser_sessions, BrowserSessionView, "preview.json")}
  end

  def render("create.json", %{browser_session: browser_session}) do
    %{data: render_one(browser_session, BrowserSessionView, "basic.json")}
  end

  def render("show.json", %{browser_session: browser_session}) do
    %{data: render_one(browser_session, BrowserSessionView, "expanded.json")}
  end

  def render("basic.json", %{browser_session: browser_session}) do
    %{
      id: browser_session.id,
      object: "browser_session",
      account_id: browser_session.account_id,
      customer_id: browser_session.customer_id,
      metadata: browser_session.metadata,
      started_at: browser_session.started_at,
      finished_at: browser_session.finished_at
    }
  end

  def render("preview.json", %{browser_session: browser_session}) do
    %{
      id: browser_session.id,
      object: "browser_session",
      account_id: browser_session.account_id,
      customer_id: browser_session.customer_id,
      metadata: browser_session.metadata,
      started_at: browser_session.started_at,
      finished_at: browser_session.finished_at,
      customer: render_one(browser_session.customer, CustomerView, "basic.json")
    }
  end

  def render("expanded.json", %{browser_session: browser_session}) do
    %{
      id: browser_session.id,
      object: "browser_session",
      account_id: browser_session.account_id,
      customer_id: browser_session.customer_id,
      metadata: browser_session.metadata,
      started_at: browser_session.started_at,
      finished_at: browser_session.finished_at,
      customer: render_one(browser_session.customer, CustomerView, "basic.json"),
      browser_replay_events:
        render_many(
          browser_session.browser_replay_events,
          BrowserReplayEventView,
          "browser_replay_event.json"
        )
    }
  end
end
