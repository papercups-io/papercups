defmodule ChatApiWeb.InboxView do
  use ChatApiWeb, :view
  alias ChatApiWeb.InboxView

  def render("index.json", %{inboxes: inboxes}) do
    %{data: render_many(inboxes, InboxView, "inbox.json")}
  end

  def render("show.json", %{inbox: inbox}) do
    %{data: render_one(inbox, InboxView, "inbox.json")}
  end

  def render("inbox.json", %{inbox: inbox}) do
    %{
      id: inbox.id,
      object: "inbox",
      name: inbox.name,
      description: inbox.description,
      slug: inbox.slug,
      is_primary: inbox.is_primary,
      is_private: inbox.is_private,
      account_id: inbox.account_id
    }
  end
end
