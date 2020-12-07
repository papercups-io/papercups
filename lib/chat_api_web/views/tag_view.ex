defmodule ChatApiWeb.TagView do
  use ChatApiWeb, :view
  alias ChatApiWeb.TagView

  def render("index.json", %{tags: tags}) do
    %{data: render_many(tags, TagView, "tag.json")}
  end

  def render("show.json", %{tag: tag}) do
    %{data: render_one(tag, TagView, "tag.json")}
  end

  def render("tag.json", %{tag: tag}) do
    %{
      id: tag.id,
      object: "tag",
      name: tag.name,
      description: tag.description,
      color: tag.color
    }
  end
end
