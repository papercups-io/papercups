defmodule ChatApiWeb.GoogleAuthorizationView do
  use ChatApiWeb, :view
  alias ChatApiWeb.GoogleAuthorizationView

  def render("index.json", %{google_authorizations: google_authorizations}) do
    %{
      data:
        render_many(google_authorizations, GoogleAuthorizationView, "google_authorization.json")
    }
  end

  def render("show.json", %{google_authorization: google_authorization}) do
    %{
      data: render_one(google_authorization, GoogleAuthorizationView, "google_authorization.json")
    }
  end

  def render("google_authorization.json", %{google_authorization: google_authorization}) do
    %{
      id: google_authorization.id,
      client: google_authorization.client,
      created_at: google_authorization.inserted_at,
      account_id: google_authorization.account_id,
      user_id: google_authorization.user_id,
      scope: google_authorization.scope
    }
  end
end
