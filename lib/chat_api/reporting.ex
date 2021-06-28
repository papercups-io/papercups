defmodule ChatApi.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  require Integer

  alias ChatApi.{
    Accounts.Account,
    Repo,
    Conversations.Conversation,
    Messages.Message,
    Users.User,
    Customers.Customer,
    Github.GithubAuthorization,
    Google.GoogleAuthorization,
    Mattermost.MattermostAuthorization,
    SlackAuthorizations.SlackAuthorization,
    Twilio.TwilioAuthorization,
    WidgetSettings.WidgetSetting
  }

  @type aggregate_by_date() :: %{date: binary(), count: integer()}
  @type aggregate_by_user() :: %{user: %{id: integer(), email: binary()}, count: integer()}
  @type aggregate_by_field() :: %{field: binary(), count: integer()}
  @type aggregate_average_by_weekday() :: %{day: binary(), average: float(), unit: atom()}

  @spec count_messages_by_date(binary(), map()) :: [aggregate_by_date()]
  def count_messages_by_date(account_id, filters \\ %{}) do
    Message
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  @spec count_messages_by_date(binary(), binary(), binary()) :: [aggregate_by_date()]
  def count_messages_by_date(account_id, from_date, to_date),
    do: count_messages_by_date(account_id, %{from_date: from_date, to_date: to_date})

  @spec count_conversations_by_date(binary(), map()) :: [aggregate_by_date()]
  def count_conversations_by_date(account_id, filters \\ %{}) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  @spec list_conversations_with_agent_reply(binary(), map()) :: [Conversation.t()]
  def list_conversations_with_agent_reply(account_id, filters \\ %{}) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> where([conv], not is_nil(conv.first_replied_at))
    |> select([:first_replied_at, :inserted_at])
    |> Repo.all()
  end

  @spec list_closed_conversations(binary(), map()) :: [Conversation.t()]
  def list_closed_conversations(account_id, filters \\ %{}) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> where([conv], not is_nil(conv.closed_at))
    |> select([:closed_at, :inserted_at])
    |> Repo.all()
  end

  @spec conversation_seconds_to_first_reply_by_date(binary(), map()) :: [map()]
  def conversation_seconds_to_first_reply_by_date(account_id, filters \\ %{}) do
    account_id
    |> list_conversations_with_agent_reply(filters)
    |> Stream.map(fn conv ->
      %{
        date: NaiveDateTime.to_date(conv.inserted_at),
        seconds_to_first_reply: calculate_seconds_to_first_reply(conv)
      }
    end)
    |> Enum.group_by(& &1.date, & &1.seconds_to_first_reply)
    |> Stream.map(fn {date, seconds_to_first_reply_list} ->
      %{
        date: date,
        seconds_to_first_reply_list: seconds_to_first_reply_list,
        average: average(seconds_to_first_reply_list),
        median: median(seconds_to_first_reply_list)
      }
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  @spec conversation_seconds_to_resolution_by_date(binary(), map()) :: [map()]
  def conversation_seconds_to_resolution_by_date(account_id, filters \\ %{}) do
    account_id
    |> list_closed_conversations(filters)
    |> Stream.map(fn conv ->
      %{
        date: NaiveDateTime.to_date(conv.inserted_at),
        seconds_to_resolution: calculate_seconds_to_resolution(conv)
      }
    end)
    |> Enum.group_by(& &1.date, & &1.seconds_to_resolution)
    |> Stream.map(fn {date, seconds_to_resolution_list} ->
      %{
        date: date,
        seconds_to_resolution_list: seconds_to_resolution_list,
        average: average(seconds_to_resolution_list),
        median: median(seconds_to_resolution_list)
      }
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  @days_per_week 7
  @seconds_per_day 60 * 60 * 24
  @seconds_per_week @seconds_per_day * @days_per_week

  @spec seconds_to_first_reply_metrics_by_week(binary(), map()) :: [map()]
  def seconds_to_first_reply_metrics_by_week(account_id, filters \\ %{}) do
    seconds_to_first_reply_list_by_date =
      account_id
      |> conversation_seconds_to_first_reply_by_date(filters)
      |> Enum.group_by(& &1.date, & &1.seconds_to_first_reply_list)
      |> Enum.map(fn {k, v} -> {k, List.flatten(v)} end)
      |> Map.new()

    filters
    |> get_weekly_chunks()
    |> Enum.map(fn {start_date, end_date} ->
      seconds_to_first_reply_list =
        start_date
        |> Date.range(end_date)
        |> Enum.reduce([], fn date, acc ->
          acc ++ Map.get(seconds_to_first_reply_list_by_date, date, [])
        end)

      %{
        start_date: start_date,
        end_date: end_date,
        seconds_to_first_reply_list: seconds_to_first_reply_list,
        average: average(seconds_to_first_reply_list),
        median: median(seconds_to_first_reply_list)
      }
    end)
  end

  @spec seconds_to_resolution_metrics_by_week(binary(), map()) :: [map()]
  def seconds_to_resolution_metrics_by_week(account_id, filters \\ %{}) do
    seconds_to_resolution_list_by_date =
      account_id
      |> conversation_seconds_to_resolution_by_date(filters)
      |> Enum.group_by(& &1.date, & &1.seconds_to_resolution_list)
      |> Enum.map(fn {k, v} -> {k, List.flatten(v)} end)
      |> Map.new()

    filters
    |> get_weekly_chunks()
    |> Enum.map(fn {start_date, end_date} ->
      seconds_to_resolution_list =
        start_date
        |> Date.range(end_date)
        |> Enum.reduce([], fn date, acc ->
          acc ++ Map.get(seconds_to_resolution_list_by_date, date, [])
        end)

      %{
        start_date: start_date,
        end_date: end_date,
        seconds_to_resolution_list: seconds_to_resolution_list,
        average: average(seconds_to_resolution_list),
        median: median(seconds_to_resolution_list)
      }
    end)
  end

  @spec get_weekly_chunks(NaiveDateTime.t(), NaiveDateTime.t()) :: [{Date.t(), Date.t()}]
  def get_weekly_chunks(from_date, to_date) do
    start = from_date |> NaiveDateTime.to_date() |> start_of_week()
    finish = to_date |> NaiveDateTime.to_date() |> end_of_week()

    start
    |> Stream.iterate(fn date -> Date.add(date, @days_per_week) end)
    |> Enum.reduce_while([], fn date, acc ->
      case Date.compare(date, finish) do
        :lt -> {:cont, [{date, Date.add(date, @days_per_week - 1)} | acc]}
        _ -> {:halt, acc}
      end
    end)
  end

  @spec get_weekly_chunks(map()) :: [{Date.t(), Date.t()}]
  def get_weekly_chunks(filters \\ %{}) do
    from_date =
      case Map.fetch(filters, :from_date) do
        {:ok, %NaiveDateTime{} = date} -> date
        {:ok, date} -> NaiveDateTime.from_iso8601!(date)
        # Default to one week ago
        :error -> NaiveDateTime.utc_now() |> NaiveDateTime.add(-1 * @seconds_per_week)
      end

    to_date =
      case Map.fetch(filters, :to_date) do
        {:ok, %NaiveDateTime{} = date} -> date
        {:ok, date} -> NaiveDateTime.from_iso8601!(date)
        :error -> NaiveDateTime.utc_now()
      end

    get_weekly_chunks(from_date, to_date)
  end

  @spec start_of_week(Date.t()) :: Date.t()
  def start_of_week(date) do
    Date.add(date, -1 * Date.day_of_week(date))
  end

  @spec end_of_week(Date.t()) :: Date.t()
  def end_of_week(date) do
    Date.add(date, 7 - Date.day_of_week(date))
  end

  # TODO: move to Conversations context?
  @spec calculate_seconds_to_first_reply(Conversation.t()) :: integer()
  def calculate_seconds_to_first_reply(conversation) do
    # The `inserted_at` field is a NaiveDateTime, so we need to convert
    # the `first_replied_at` field to make this diff work
    conversation.first_replied_at
    |> DateTime.to_naive()
    |> NaiveDateTime.diff(conversation.inserted_at)
  end

  @spec average_seconds_to_first_reply(binary(), map()) :: float()
  def average_seconds_to_first_reply(account_id, filters \\ %{}) do
    account_id
    |> list_conversations_with_agent_reply(filters)
    |> compute_average_seconds_to_first_reply()
  end

  @spec compute_average_seconds_to_first_reply([Conversation.t()]) :: float()
  def compute_average_seconds_to_first_reply(conversations) do
    conversations
    |> Enum.map(&calculate_seconds_to_first_reply/1)
    |> average()
  end

  @spec median_seconds_to_first_reply(binary(), map()) :: float()
  def median_seconds_to_first_reply(account_id, filters \\ %{}) do
    account_id
    |> list_conversations_with_agent_reply(filters)
    |> compute_median_seconds_to_first_reply()
  end

  @spec compute_median_seconds_to_first_reply([Conversation.t()]) :: float()
  def compute_median_seconds_to_first_reply(conversations) do
    conversations
    |> Enum.map(&calculate_seconds_to_first_reply/1)
    |> median()
  end

  # TODO: move to Conversations context?
  @spec calculate_seconds_to_resolution(Conversation.t()) :: integer()
  def calculate_seconds_to_resolution(conversation) do
    # The `inserted_at` field is a NaiveDateTime, so we need to convert
    # the `closed_at` field to make this diff work
    conversation.closed_at
    |> DateTime.to_naive()
    |> NaiveDateTime.diff(conversation.inserted_at)
  end

  @spec average_seconds_to_resolution(binary(), map()) :: float()
  def average_seconds_to_resolution(account_id, filters \\ %{}) do
    account_id
    |> list_closed_conversations(filters)
    |> compute_average_seconds_to_resolution()
  end

  @spec compute_average_seconds_to_resolution([Conversation.t()]) :: float()
  def compute_average_seconds_to_resolution(conversations) do
    conversations
    |> Enum.map(&calculate_seconds_to_resolution/1)
    |> average()
  end

  @spec median_seconds_to_resolution(binary(), map()) :: float()
  def median_seconds_to_resolution(account_id, filters \\ %{}) do
    account_id
    |> list_closed_conversations(filters)
    |> compute_median_seconds_to_resolution()
  end

  @spec compute_median_seconds_to_resolution([Conversation.t()]) :: float()
  def compute_median_seconds_to_resolution(conversations) do
    conversations
    |> Enum.map(&calculate_seconds_to_resolution/1)
    |> median()
  end

  @spec average([integer()]) :: float()
  def average([]), do: 0.0

  def average(list) do
    Enum.sum(list) / length(list)
  end

  @spec median([integer()]) :: number()
  def median([]), do: 0

  def median(list) do
    case length(list) do
      n when Integer.is_even(n) ->
        finish = list |> length() |> div(2)
        start = finish - 1

        list |> Enum.sort() |> Enum.slice(start..finish) |> average()

      n when Integer.is_odd(n) ->
        midpoint = list |> length() |> div(2)

        list |> Enum.sort() |> Enum.at(midpoint)

      _ ->
        0
    end
  end

  @spec count_conversations_by_date(binary(), binary(), binary()) :: [aggregate_by_date()]
  def count_conversations_by_date(account_id, from_date, to_date),
    do: count_conversations_by_date(account_id, %{from_date: from_date, to_date: to_date})

  @spec count_customers_by_date(binary(), map()) :: [aggregate_by_date()]
  def count_customers_by_date(account_id, filters \\ %{}) do
    Customer
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  @spec count_customers_by_date(binary(), binary(), binary()) :: [aggregate_by_date()]
  def count_customers_by_date(account_id, from_date, to_date),
    do: count_customers_by_date(account_id, %{from_date: from_date, to_date: to_date})

  @spec count_messages_per_user(binary(), map()) :: [aggregate_by_user()]
  def count_messages_per_user(account_id, filters \\ %{}) do
    Message
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> join(:inner, [m], u in User, on: m.user_id == u.id)
    |> select([m, u], %{user: %{id: u.id, email: u.email}, count: count(m.user_id)})
    |> group_by([m, u], [m.user_id, u.id])
    |> Repo.all()
  end

  @spec count_sent_messages_by_date(binary(), map()) :: [aggregate_by_date()]
  def count_sent_messages_by_date(account_id, filters \\ %{}) do
    Message
    |> where(account_id: ^account_id)
    |> where([message], not is_nil(message.user_id))
    |> where(^filter_where(filters))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  @spec count_received_messages_by_date(binary(), map()) :: [aggregate_by_date()]
  def count_received_messages_by_date(account_id, filters \\ %{}) do
    Message
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> where([message], not is_nil(message.customer_id))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  @spec count_messages_by_weekday(binary(), map()) :: [aggregate_average_by_weekday()]
  def count_messages_by_weekday(account_id, filters \\ %{}) do
    Message
    |> where(account_id: ^account_id)
    |> where([m], not is_nil(m.customer_id))
    |> where(^filter_where(filters))
    |> count_grouped_by_date()
    |> select_merge([m], %{day: fragment("to_char(date(?), 'Day')", m.inserted_at)})
    |> Repo.all()
    |> Enum.group_by(&String.trim(&1.day))
    |> compute_weekday_aggregates()
  end

  @spec count_grouped_by_date(Ecto.Query.t(), atom()) :: Ecto.Query.t()
  def count_grouped_by_date(query, field \\ :inserted_at) do
    query
    |> group_by([r], fragment("date(?)", field(r, ^field)))
    |> select([r], %{date: fragment("date(?)", field(r, ^field)), count: count(r.id)})
    |> order_by([r], asc: fragment("date(?)", field(r, ^field)))
  end

  @spec compute_weekday_aggregates(map()) :: [map()]
  def compute_weekday_aggregates(grouped) do
    Enum.map(weekdays(), fn weekday ->
      records = Map.get(grouped, weekday, [])
      total = Enum.reduce(records, 0, fn x, acc -> x.count + acc end)

      %{
        day: weekday,
        average: total / max(length(records), 1),
        total: total
      }
    end)
  end

  @spec get_customer_breakdown(binary(), atom(), map()) :: [aggregate_by_field()]
  def get_customer_breakdown(account_id, field, filters \\ %{}) do
    Customer
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> group_by([r], field(r, ^field))
    |> select([r], {field(r, ^field), count(r.id)})
    |> order_by([r], desc: count(r.id))
    |> Repo.all()
    |> Enum.map(fn {value, count} -> %{field => value, :count => count} end)
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:from_date, value}, dynamic ->
        dynamic([r], ^dynamic and r.inserted_at > ^value)

      {:to_date, value}, dynamic ->
        dynamic([r], ^dynamic and r.inserted_at < ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp weekdays, do: ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

  ####################################################################################
  # Internal metrics
  ####################################################################################

  def send_weekly_report() do
    metrics = generate_weekly_report()

    # num_new_accounts
    # active_accounts_with_messages
    # num_new_users
    # active_users_with_messages
    # num_widget_installations
    # num_new_messages
    # num_messages_by_source
    # num_new_conversations
    # num_conversations_by_source
    # num_new_customers
    # num_customers_by_account
    # num_customers_by_host
    # num_new_integrations

    payload = %{
      "text" => "Weekly metrics for Papercups",
      "blocks" => [
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => "Here are this weeks metrics:"
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
    today = DateTime.utc_now()
    one_week_ago = DateTime.add(today, -1 * @seconds_per_week)
    this_week = %{from_date: one_week_ago, to_date: today}

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
      num_new_accounts: count_new_accounts(filters),
      active_accounts_with_messages: list_active_accounts(filters),
      num_new_users: count_new_users(filters),
      active_users_with_messages: list_active_users(filters),
      num_widget_installations: count_widget_installations(filters),
      num_new_messages: count_new_messages(filters),
      num_messages_by_source: group_messages_by_source(filters),
      num_new_conversations: count_new_conversations(filters),
      num_conversations_by_source: group_conversations_by_source(filters),
      num_new_customers: count_new_customers(filters),
      num_customers_by_account: group_customers_by_account(filters),
      num_customers_by_host: group_customers_by_host(filters),
      num_new_integrations: count_new_integrations(filters)
      # stripe_subscription_metrics: stripe_subscription_metrics(filters)
    }
  end

  def count_new_accounts(filters \\ %{}) do
    Account
    |> where(^filter_where(filters))
    |> select([a], count(a.id))
    |> Repo.one()
  end

  def list_active_accounts(filters \\ %{}) do
    filters
    # result looks like [%{count: 1678, account: %{company_name: "Papercups", id: "a1b2c3"}}]
    |> group_messages_by_account()
    |> Enum.filter(fn r -> r.count > 0 end)
    |> Enum.sort_by(fn r -> r.count end, :desc)

    # |> Enum.map(fn r -> r.account end)
  end

  def count_new_users(filters \\ %{}) do
    User
    |> where(^filter_where(filters))
    |> select([u], count(u.id))
    |> Repo.one()
  end

  def list_active_users(filters \\ %{}) do
    filters
    # result looks like [%{count: 1678, user: %{email: "alexreichert621@gmail.com", id: 1}}]
    |> group_messages_by_user()
    |> Enum.filter(fn r -> r.count > 0 end)
    |> Enum.sort_by(fn r -> r.count end, :desc)
  end

  def count_widget_installations(filters \\ %{}) do
    WidgetSetting
    |> where(^filter_where(filters))
    |> where([w], not ilike(w.host, "papercups"))
    |> where([w], not ilike(w.host, "localhost"))
    |> select([w], count(w.id))
    |> Repo.one()
  end

  def count_new_messages(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> select([m], count(m.id))
    |> Repo.one()
  end

  def group_messages_by_account(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> join(:inner, [m], a in Account, on: m.account_id == a.id)
    |> select([m, a], %{
      account: %{id: a.id, company_name: a.company_name},
      count: count(m.account_id)
    })
    |> group_by([m, a], [m.account_id, a.id])
    |> order_by([m], desc: count(m.account_id))
    |> Repo.all()
  end

  def group_messages_by_user(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> join(:inner, [m], u in User, on: m.user_id == u.id)
    |> select([m, u], %{
      user: %{id: u.id, email: u.email},
      count: count(m.user_id)
    })
    |> group_by([m, u], [m.user_id, u.id])
    |> order_by([m], desc: count(m.user_id))
    |> Repo.all()
  end

  def group_messages_by_source(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> select([m], %{source: m.source, count: count(m.id)})
    |> group_by([m], [m.source])
    |> order_by([m], desc: count(m.id))
    |> Repo.all()
  end

  def count_new_conversations(filters \\ %{}) do
    Conversation
    |> where(^filter_where(filters))
    |> select([c], count(c.id))
    |> Repo.one()
  end

  def group_conversations_by_account(filters \\ %{}) do
    Conversation
    |> where(^filter_where(filters))
    |> join(:inner, [c], a in Account, on: c.account_id == a.id)
    |> select([c, a], %{
      account: %{id: a.id, company_name: a.company_name},
      count: count(c.account_id)
    })
    |> group_by([c, a], [c.account_id, a.id])
    |> order_by([c], desc: count(c.account_id))
    |> Repo.all()
  end

  def group_conversations_by_source(filters \\ %{}) do
    Conversation
    |> where(^filter_where(filters))
    |> select([c], %{source: c.source, count: count(c.id)})
    |> group_by([c], [c.source])
    |> order_by([c], desc: count(c.id))
    |> Repo.all()
  end

  def count_new_customers(filters \\ %{}) do
    Customer
    |> where(^filter_where(filters))
    |> select([c], count(c.id))
    |> Repo.one()
  end

  def group_customers_by_account(filters \\ %{}) do
    Customer
    |> where(^filter_where(filters))
    |> join(:inner, [c], a in Account, on: c.account_id == a.id)
    |> select([c, a], %{
      account: %{id: a.id, company_name: a.company_name},
      count: count(c.account_id)
    })
    |> group_by([c, a], [c.account_id, a.id])
    |> order_by([c], desc: count(c.account_id))
    |> Repo.all()
  end

  def group_customers_by_host(filters \\ %{}) do
    Customer
    |> where(^filter_where(filters))
    |> select([c], %{host: c.host, count: count(c.id)})
    |> group_by([c], [c.host])
    |> order_by([c], desc: count(c.id))
    |> Repo.all()
  end

  def count_new_integrations(filters \\ %{}) do
    github =
      GithubAuthorization
      |> where(^filter_where(filters))
      |> select([a], count(a.id))
      |> Repo.one()

    google =
      GoogleAuthorization
      |> where(^filter_where(filters))
      |> select([a], count(a.id))
      |> Repo.one()

    mattermost =
      MattermostAuthorization
      |> where(^filter_where(filters))
      |> select([a], count(a.id))
      |> Repo.one()

    slack =
      SlackAuthorization
      |> where(^filter_where(filters))
      |> select([a], count(a.id))
      |> Repo.one()

    twilio =
      TwilioAuthorization
      |> where(^filter_where(filters))
      |> select([a], count(a.id))
      |> Repo.one()

    %{
      github: github,
      google: google,
      mattermost: mattermost,
      slack: slack,
      twilio: twilio,
      total: github + google + mattermost + slack + twilio
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

  # Last changelog update (query github?)
  # -> curl https://raw.githubusercontent.com/papercups-io/papercups/master/CHANGELOG.md
  # Number of Mailgun emails sent?
  # Number of Customer IO emails sent?
  # Number of personal outbound emails sent (excluding replies to inbound)?
  # -> (will require personal Gmail authorization)
  # Number of customers/users contacted (using Google Sheets API?)
end
