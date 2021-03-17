defmodule ChatApiWeb.CannedResponseView do
  use ChatApiWeb, :view
  alias ChatApiWeb.CannedResponseView

  def render("index.json", %{canned_responses: canned_responses}) do
    %{data: render_many(canned_responses, CannedResponseView, "canned_response.json")}
  end

  def render("show.json", %{canned_response: canned_response}) do
    %{data: render_one(canned_response, CannedResponseView, "canned_response.json")}
  end

  def render("canned_response.json", %{canned_response: canned_response}) do
    %{id: canned_response.id, name: canned_response.name, content: canned_response.content}
  end
end
