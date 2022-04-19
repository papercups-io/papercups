defmodule ChatApiWeb.MentionView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{MentionView, UserView}

  def render("index.json", %{mentions: mentions}) do
    %{data: render_many(mentions, MentionView, "user.json")}
  end

  def render("show.json", %{mention: mention}) do
    %{data: render_one(mention, MentionView, "mention.json")}
  end

  def render("mention.json", %{mention: mention}) do
    %{
      id: mention.id,
      object: "mention",
      account_id: mention.account_id,
      created_at: mention.inserted_at,
      seen_at: mention.seen_at,
      conversation_id: mention.conversation_id,
      message_id: mention.message_id,
      user_id: mention.user_id,
      user: render_one(mention.user, UserView, "user.json")
    }
  end
end
