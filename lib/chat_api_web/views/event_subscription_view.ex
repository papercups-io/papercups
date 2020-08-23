defmodule ChatApiWeb.EventSubscriptionView do
  use ChatApiWeb, :view
  alias ChatApiWeb.EventSubscriptionView

  def render("index.json", %{event_subscriptions: event_subscriptions}) do
    %{data: render_many(event_subscriptions, EventSubscriptionView, "event_subscription.json")}
  end

  def render("show.json", %{event_subscription: event_subscription}) do
    %{data: render_one(event_subscription, EventSubscriptionView, "event_subscription.json")}
  end

  def render("event_subscription.json", %{event_subscription: event_subscription}) do
    %{
      id: event_subscription.id,
      created_at: event_subscription.inserted_at,
      updated_at: event_subscription.updated_at,
      webhook_url: event_subscription.webhook_url,
      verified: event_subscription.verified,
      account_id: event_subscription.account_id,
      scope: event_subscription.scope
    }
  end
end
