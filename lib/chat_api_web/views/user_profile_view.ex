defmodule ChatApiWeb.UserProfileView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UserProfileView

  def render("index.json", %{profiles: profiles}) do
    %{data: render_many(profiles, UserProfileView, "user_profile.json")}
  end

  def render("show.json", %{user_profile: user_profile}) do
    %{data: render_one(user_profile, UserProfileView, "user_profile.json")}
  end

  def render("user_profile.json", %{user_profile: user_profile}) do
    %{
      id: user_profile.id,
      user_id: user_profile.user_id,
      full_name: user_profile.full_name,
      display_name: user_profile.display_name,
      profile_photo_url: user_profile.profile_photo_url
    }
  end
end
