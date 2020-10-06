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
    filters = %{from_date: from_date, to_date: to_date}

    json(conn, %{
      data: %{
        messages_by_date: Reporting.count_messages_by_date(account_id, filters),
        conversations_by_date: Reporting.count_conversations_by_date(account_id, filters),
        messages_per_user: Reporting.count_messages_per_user(account_id, filters),
        messages_by_weekday: Reporting.count_messages_by_weekday(account_id, filters),
        sent_messages_by_date: Reporting.count_sent_messages_by_date(account_id, filters),
        received_messages_by_date: Reporting.count_received_messages_by_date(account_id, filters)
      }
    })
  end
end
