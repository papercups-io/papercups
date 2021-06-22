defmodule ChatApiWeb.ReportingController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.Reporting

  action_fallback(ChatApiWeb.FallbackController)

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
        received_messages_by_date: Reporting.count_received_messages_by_date(account_id, filters),
        average_time_to_first_reply:
          Reporting.average_seconds_to_first_reply(account_id, filters),
        median_time_to_first_reply: Reporting.median_seconds_to_first_reply(account_id, filters),
        first_reply_metrics_by_week:
          Reporting.seconds_to_first_reply_metrics_by_week(account_id, filters),
        average_time_to_resolution: Reporting.average_seconds_to_resolution(account_id, filters),
        median_time_to_resolution: Reporting.median_seconds_to_resolution(account_id, filters),
        resolution_metrics_by_week:
          Reporting.seconds_to_resolution_metrics_by_week(account_id, filters)
        # NB: this are currently unused
        # customer_breakdown_by_browser:
        #   Reporting.get_customer_breakdown(account_id, :browser, filters),
        # customer_breakdown_by_os: Reporting.get_customer_breakdown(account_id, :os, filters),
        # customer_breakdown_by_time_zone:
        #   Reporting.get_customer_breakdown(account_id, :time_zone, filters),
      }
    })
  end

  def index(conn, params) do
    conn
    |> put_status(400)
    |> json(%{
      error: %{
        status: 400,
        message: "The following parameters are required: from_date, to_date",
        received: Map.keys(params)
      }
    })
  end
end
