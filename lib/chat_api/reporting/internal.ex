defmodule ChatApi.Reporting.Internal do
  @moduledoc """
  Logic for internal reporting metrics
  """

  import Ecto.Query, warn: false
  require Integer

  alias ChatApi.Reporting

  @days_per_week 7
  @seconds_per_day 60 * 60 * 24
  @seconds_per_week @seconds_per_day * @days_per_week

  def send_weekly_report() do
    send_weekly_report(DateTime.utc_now())
  end

  def send_weekly_report(datetime) do
    metrics = generate_weekly_report(datetime)
    date = datetime |> DateTime.to_date() |> Date.to_string()

    payload = %{
      "text" => "Weekly metrics report: #{date}",
      "blocks" => [
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => ":chart_with_upwards_trend: Weekly metrics report: #{date}"
          }
        },
        %{
          "type" => "section",
          "fields" => [
            %{
              "type" => "mrkdwn",
              "text" => """
              *New accounts:*
              > #{metrics.current.num_new_accounts} (#{metrics.previous.num_new_accounts} last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New users:*
              > #{metrics.current.num_new_users} (#{metrics.previous.num_new_users} last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Most active accounts:*
              #{
                metrics.current.active_accounts_with_messages
                |> Enum.map(fn r ->
                  "> #{r.account.company_name} (#{r.count} messages)"
                end)
                |> Enum.slice(0..4)
                |> Enum.join("\n")
              }

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Most active users:*
              #{
                metrics.current.active_users_with_messages
                |> Enum.map(fn r ->
                  "> #{r.user.email} (#{r.count} messages)"
                end)
                |> Enum.slice(0..4)
                |> Enum.join("\n")
              }

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New widget installations:*
              > #{metrics.current.num_widget_installations} (#{
                metrics.previous.num_widget_installations
              } last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New messages:*
              > #{metrics.current.num_new_messages} (#{metrics.previous.num_new_messages} last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New conversations:*
              > #{metrics.current.num_new_conversations} (#{
                metrics.previous.num_new_conversations
              } last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New customers:*
              > #{metrics.current.num_new_customers} (#{metrics.previous.num_new_customers} last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New integrations:*
              > _Slack_: #{metrics.current.num_new_integrations.slack} (#{
                metrics.previous.num_new_integrations.slack
              } last week)
              > _Mattermost_: #{metrics.current.num_new_integrations.mattermost} (#{
                metrics.previous.num_new_integrations.mattermost
              } last week)
              > _Google_: #{metrics.current.num_new_integrations.google} (#{
                metrics.previous.num_new_integrations.google
              } last week)
              > _Twilio_: #{metrics.current.num_new_integrations.twilio} (#{
                metrics.previous.num_new_integrations.twilio
              } last week)
              > _Github_: #{metrics.current.num_new_integrations.github} (#{
                metrics.previous.num_new_integrations.github
              } last week)

              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *New customers by account:*
              #{
                metrics.current.num_customers_by_account
                |> Enum.map(fn r ->
                  "> #{r.account.company_name} (#{r.count} new customers)"
                end)
                |> Enum.slice(0..4)
                |> Enum.join("\n")
              }

              """
            }
          ]
        },
        %{
          "type" => "divider"
        },
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => "Overall metrics:"
          }
        },
        %{
          "type" => "section",
          "fields" => [
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total accounts:*
              > #{metrics.total.num_new_accounts}
              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total users:*
              > #{metrics.total.num_new_users}
              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total widget installations:*
              > #{metrics.total.num_widget_installations}
              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total messages:*
              > #{metrics.total.num_new_messages}
              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total conversations:*
              > #{metrics.total.num_new_conversations}
              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total customers:*
              > #{metrics.total.num_new_customers}
              """
            },
            %{
              "type" => "mrkdwn",
              "text" => """
              *Total integrations:*
              > _Slack_: #{metrics.total.num_new_integrations.slack}
              > _Mattermost_: #{metrics.total.num_new_integrations.mattermost}
              > _Google_: #{metrics.total.num_new_integrations.google}
              > _Twilio_: #{metrics.total.num_new_integrations.twilio}
              > _Github_: #{metrics.total.num_new_integrations.github}

              """
            }
          ]
        }
      ]
    }

    ChatApi.Slack.Notification.log(payload)
  end

  def generate_weekly_report() do
    generate_weekly_report(DateTime.utc_now())
  end

  def generate_weekly_report(datetime) do
    one_week_ago = DateTime.add(datetime, -1 * @seconds_per_week)
    this_week = %{from_date: one_week_ago, to_date: datetime}

    last_week = %{
      from_date: DateTime.add(one_week_ago, -1 * @seconds_per_week),
      to_date: one_week_ago
    }

    %{
      current: generate_internal_metrics(this_week),
      previous: generate_internal_metrics(last_week),
      total: generate_internal_metrics()
    }
  end

  def generate_internal_metrics(filters \\ %{}) do
    %{
      num_new_accounts: Reporting.count_new_accounts(filters),
      active_accounts_with_messages: Reporting.list_active_accounts(filters),
      num_new_users: Reporting.count_new_users(filters),
      active_users_with_messages: Reporting.list_active_users(filters),
      num_widget_installations: Reporting.count_widget_installations(filters),
      num_new_messages: Reporting.count_new_messages(filters),
      num_messages_by_source: Reporting.group_messages_by_source(filters),
      num_new_conversations: Reporting.count_new_conversations(filters),
      num_conversations_by_source: Reporting.group_conversations_by_source(filters),
      num_new_customers: Reporting.count_new_customers(filters),
      num_customers_by_account: Reporting.group_customers_by_account(filters),
      num_customers_by_host: Reporting.group_customers_by_host(filters),
      num_new_integrations: Reporting.count_new_integrations(filters)
      # stripe_subscription_metrics: stripe_subscription_metrics(filters)
    }
  end

  def stripe_subscription_metrics(filters \\ %{}) do
    case Stripe.Subscription.list(%{limit: 100}) do
      {:ok, %{data: data}} ->
        paid_subscriptions = Enum.filter(data, &is_paid_subscription?/1)

        # TODO: include comparisons with previous week?
        metrics = %{
          total: Enum.count(paid_subscriptions),
          current:
            paid_subscriptions
            |> Enum.filter(fn sub ->
              case filters do
                %{from_date: from, to_date: to} -> sub.start_date > from && sub.start_date < to
                %{from_date: from} -> sub.start_date > from
                %{to_date: to} -> sub.start_date < to
                _ -> true
              end
            end)
            |> Enum.count(),
          mrr:
            paid_subscriptions
            |> Enum.filter(&is_active_subscription?/1)
            |> Enum.reduce(0, fn sub, total ->
              total + calculate_subscription_mrr(sub)
            end)
        }

        {:ok, metrics}

      error ->
        error
    end
  end

  def is_paid_subscription?(%Stripe.Subscription{plan: %Stripe.Plan{active: true, amount: amount}}),
      do: amount > 0

  def is_paid_subscription?(_), do: false

  def is_active_subscription?(%Stripe.Subscription{status: "active"}), do: true
  def is_active_subscription?(_), do: false

  def calculate_subscription_mrr(%Stripe.Subscription{} = subscription) do
    case subscription do
      %{
        plan: %Stripe.Plan{active: true, amount: amount},
        discount: %Stripe.Discount{
          coupon: %Stripe.Coupon{
            duration: "forever",
            amount_off: amount_off,
            percent_off: percent_off
          }
        }
      } ->
        a = min(amount_off || 0, amount)
        p = min(amount * ((percent_off || 0) / 100), amount)

        amount - a - p

      %{plan: %Stripe.Plan{active: true, amount: amount}} ->
        amount

      _ ->
        0
    end
  end

  # Optional:

  def pull_last_changelog_update() do
    # TOOD: parse https://raw.githubusercontent.com/papercups-io/papercups/master/CHANGELOG.md
  end

  def count_outbound_emails_sent() do
    # TODO: fetch via Gmail API to count how often we're sending outbound emails
  end
end
