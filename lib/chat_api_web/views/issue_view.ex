defmodule ChatApiWeb.IssueView do
  use ChatApiWeb, :view
  alias ChatApiWeb.IssueView

  def render("index.json", %{issues: issues}) do
    %{data: render_many(issues, IssueView, "issue.json")}
  end

  def render("show.json", %{issue: issue}) do
    %{data: render_one(issue, IssueView, "issue.json")}
  end

  def render("issue.json", %{issue: issue}) do
    %{
      id: issue.id,
      object: "issue",
      created_at: issue.inserted_at,
      updated_at: issue.updated_at,
      title: issue.title,
      body: issue.body,
      state: issue.state,
      github_issue_url: issue.github_issue_url,
      closed_at: issue.closed_at,
      account_id: issue.account_id,
      creator_id: issue.creator_id,
      assignee_id: issue.assignee_id
    }
  end
end
