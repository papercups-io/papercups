defmodule ChatApiWeb.UserSettingsController do
  use ChatApiWeb, :controller

  alias ChatApi.Users

  action_fallback ChatApiWeb.FallbackController

  def show(conn, _params) do
    with %{id: user_id} <- conn.assigns.current_user do
      user_settings = Users.get_user_settings(user_id)
      render(conn, "show.json", user_settings: user_settings)
    end
  end

  def create_or_update(conn, %{"user_settings" => user_settings_params}) do
    with %{id: user_id} <- conn.assigns.current_user do
      params = Map.merge(user_settings_params, %{"user_id" => user_id})
      {:ok, user_settings} = Users.create_or_update_settings(user_id, params)

      render(conn, "show.json", user_settings: user_settings)
    end
  end
end
