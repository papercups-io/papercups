defmodule ChatApiWeb.ReportingController do
  use ChatApiWeb, :controller

  alias ChatApi.Reporting

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    json(conn, %{
      data: %{
        messages_by_day: Reporting.messages_by_day(),
        conversations_by_day: Reporting.conversations_by_day()
      }
    })
  end
end
