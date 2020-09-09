defmodule ChatApiWeb.UserProfileController do
  use ChatApiWeb, :controller

  alias ChatApi.Users

  action_fallback ChatApiWeb.FallbackController

  def show(conn, _params) do
    with %{id: user_id} <- conn.assigns.current_user do
      user_profile = Users.get_user_info(user_id)
      render(conn, "show.json", user_profile: user_profile)
    end
  end

  def create_or_update(conn, %{"user_profile" => user_profile_params}) do
    with %{id: user_id} <- conn.assigns.current_user,
         params <- Map.merge(user_profile_params, %{"user_id" => user_id}),
         {:ok, _user_profile} <- Users.create_or_update_profile(user_id, params) do
      user_profile = Users.get_user_info(user_id)
      render(conn, "show.json", user_profile: user_profile)
    end
  end
end
