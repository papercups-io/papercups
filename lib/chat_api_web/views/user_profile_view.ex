defmodule ChatApiWeb.UserProfileView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UserView

  def render("show.json", %{user_profile: user_profile}) do
    %{data: render_one(user_profile, UserView, "user.json")}
  end
end
