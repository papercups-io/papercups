defmodule ChatApiWeb.UserSettingsController do
  use ChatApiWeb, :controller

  alias ChatApi.Users

  action_fallback ChatApiWeb.FallbackController

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, _params) do
    with %{id: user_id} <- conn.assigns.current_user do
      user_settings = Users.get_user_settings(user_id)
      render(conn, "show.json", user_settings: user_settings)
    end
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"user_settings" => user_settings_params}) do
    with %{id: user_id} <- conn.assigns.current_user do
      params = Map.merge(user_settings_params, %{"user_id" => user_id})
      {:ok, user_settings} = Users.update_user_settings(user_id, params)
      render(conn, "show.json", user_settings: user_settings)
    end
  end
end
