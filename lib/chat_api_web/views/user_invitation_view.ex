defmodule ChatApiWeb.UserInvitationView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UserInvitationView

  def render("index.json", %{user_invitations: user_invitations}) do
    %{data: render_many(user_invitations, UserInvitationView, "user_invitation.json")}
  end

  def render("show.json", %{user_invitation: user_invitation}) do
    %{data: render_one(user_invitation, UserInvitationView, "user_invitation.json")}
  end

  def render("user_invitation.json", %{user_invitation: user_invitation}) do
    %{
      id: user_invitation.id,
      account_id: user_invitation.account_id,
      expires_at: user_invitation.expires_at
    }
  end
end
