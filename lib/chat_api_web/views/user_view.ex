defmodule ChatApiWeb.UserView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UserView

  alias ChatApi.Users.UserProfile

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    case user do
      %{profile: %UserProfile{} = profile} ->
        %{
          id: user.id,
          email: user.email,
          created_at: user.inserted_at,
          full_name: profile.full_name,
          display_name: profile.display_name,
          profile_photo_url: profile.profile_photo_url
        }

      _ ->
        %{id: user.id, email: user.email, created_at: user.inserted_at}
    end
  end
end
