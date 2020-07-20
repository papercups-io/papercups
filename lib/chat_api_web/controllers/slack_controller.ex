defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  action_fallback ChatApiWeb.FallbackController

  def webhook(conn, payload) do
    IO.inspect("!!!")
    IO.inspect(payload)

    case payload do
      %{"challenge" => challenge} ->
        send_resp(conn, 200, challenge)

      _ ->
        send_resp(conn, 200, "")
    end
  end
end
