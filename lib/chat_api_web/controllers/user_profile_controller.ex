defmodule ChatApiWeb.UserProfileController do
  use ChatApiWeb, :controller

  alias ChatApi.UserProfiles

  action_fallback ChatApiWeb.FallbackController

  def show(conn, _params) do
    with %{id: user_id} <- conn.assigns.current_user do
      user_profile = UserProfiles.get_user_profile(user_id)
      render(conn, "show.json", user_profile: user_profile)
    end
  end

  def create_or_update(conn, %{"user_profile" => user_profile_params}) do
    with %{id: user_id} <- conn.assigns.current_user do
      params = Map.merge(user_profile_params, %{"user_id" => user_id})
      {:ok, user_profile} = UserProfiles.create_or_update(user_id, params)

      render(conn, "show.json", user_profile: user_profile)
    end
  end
end
