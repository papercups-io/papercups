defmodule ChatApiWeb.BrowserSessionView do
  use ChatApiWeb, :view
  alias ChatApiWeb.BrowserSessionView

  def render("index.json", %{browser_sessions: browser_sessions}) do
    %{data: render_many(browser_sessions, BrowserSessionView, "browser_session.json")}
  end

  def render("show.json", %{browser_session: browser_session}) do
    %{data: render_one(browser_session, BrowserSessionView, "browser_session.json")}
  end

  def render("browser_session.json", %{browser_session: browser_session}) do
    %{
      id: browser_session.id,
      account_id: browser_session.account_id,
      customer_id: browser_session.customer_id,
      metadata: browser_session.metadata,
      started_at: browser_session.started_at,
      finished_at: browser_session.finished_at
    }
  end
end
