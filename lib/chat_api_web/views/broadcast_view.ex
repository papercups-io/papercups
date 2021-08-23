defmodule ChatApiWeb.BroadcastView do
  use ChatApiWeb, :view
  alias ChatApiWeb.BroadcastView

  def render("index.json", %{broadcasts: broadcasts}) do
    %{data: render_many(broadcasts, BroadcastView, "broadcast.json")}
  end

  def render("show.json", %{broadcast: broadcast}) do
    %{data: render_one(broadcast, BroadcastView, "broadcast.json")}
  end

  def render("broadcast.json", %{broadcast: broadcast}) do
    %{
      id: broadcast.id,
      object: "broadcast",
      created_at: broadcast.inserted_at,
      updated_at: broadcast.updated_at,
      name: broadcast.name,
      description: broadcast.description,
      state: broadcast.state,
      started_at: broadcast.started_at,
      finished_at: broadcast.finished_at,
      account_id: broadcast.account_id,
      message_template_id: broadcast.message_template_id
    }
  end
end
