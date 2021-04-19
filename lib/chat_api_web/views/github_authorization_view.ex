defmodule ChatApiWeb.GithubAuthorizationView do
  use ChatApiWeb, :view
  alias ChatApiWeb.GithubAuthorizationView

  def render("index.json", %{github_authorizations: github_authorizations}) do
    %{
      data:
        render_many(github_authorizations, GithubAuthorizationView, "github_authorization.json")
    }
  end

  def render("show.json", %{github_authorization: github_authorization}) do
    %{
      data: render_one(github_authorization, GithubAuthorizationView, "github_authorization.json")
    }
  end

  def render("github_authorization.json", %{github_authorization: github_authorization}) do
    %{
      id: github_authorization.id,
      token_type: github_authorization.token_type,
      scope: github_authorization.scope,
      user_id: github_authorization.user_id,
      account_id: github_authorization.account_id
    }
  end
end
