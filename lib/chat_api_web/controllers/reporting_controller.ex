defmodule ChatApiWeb.ReportingController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Reporting

  action_fallback ChatApiWeb.FallbackController

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: %{account_id: account_id}}} = conn, %{
        "from_date" => from_date,
        "to_date" => to_date
      }) do
    Logger.info("Fetching reporting from #{from_date} to #{to_date}")

    json(conn, %{
      data: %{
        # TODO: incorporate the `from_date` and `to_date` into the methods below
        messages_by_date: Reporting.messages_by_date(account_id, from_date, to_date),
        conversations_by_date: Reporting.conversations_by_date(account_id, from_date, to_date)
      }
    })
  end
end
