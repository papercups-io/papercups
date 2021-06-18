defmodule ChatApiWeb.UserView do
  use ChatApiWeb, :view
  alias ChatApiWeb.UserView

  alias ChatApi.Users.UserProfile

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    case user do
      %{profile: %UserProfile{} = profile} ->
        %{
          id: user.id,
          object: "user",
          email: user.email,
          created_at: user.inserted_at,
          disabled_at: user.disabled_at,
          full_name: profile.full_name,
          display_name: profile.display_name,
          profile_photo_url: profile.profile_photo_url,
          role: user.role
        }

      _ ->
        %{
          id: user.id,
          object: "user",
          email: user.email,
          created_at: user.inserted_at,
          disabled_at: user.disabled_at,
          role: user.role
        }
    end
  end
end
