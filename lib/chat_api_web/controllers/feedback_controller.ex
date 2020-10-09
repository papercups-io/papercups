defmodule ChatApiWeb.FeedbackController do
  use ChatApiWeb, :controller

  action_fallback ChatApiWeb.FallbackController

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"message" => message}) do
    ChatApi.Slack.log("Feedback from #{conn.assigns.current_user.email}: #{message}")

    json(conn, %{data: %{ok: true}})
  end
end
