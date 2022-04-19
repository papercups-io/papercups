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

  defp exclude_admin_account(query, field \\ :account_id) do
    case System.get_env("PAPERCUPS_ADMIN_ACCOUNT_ID") do
      nil ->
        query

      "" ->
        query

      account_id when is_binary(account_id) ->
        query |> where([r], field(r, ^field) != ^account_id)
    end
  end

  defp weekdays, do: ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

  ####################################################################################
  # Internal metrics
  ####################################################################################

  @spec count_new_accounts(map()) :: number()
  def count_new_accounts(filters \\ %{}) do
    Account
    |> where(^filter_where(filters))
    |> exclude_admin_account(:id)
    |> select([a], count(a.id))
    |> Repo.one()
  end

  @spec list_active_accounts(map()) :: list()
  def list_active_accounts(filters \\ %{}) do
    filters
    # Result looks like [%{count: 1678, account: %{company_name: "Papercups", id: "a1b2c3"}}]
    |> group_messages_by_account()
    |> Enum.filter(fn r -> r.count > 0 end)
    |> Enum.sort_by(fn r -> r.count end, :desc)
  end

  @spec count_new_users(map()) :: number()
  def count_new_users(filters \\ %{}) do
    User
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([u], count(u.id))
    |> Repo.one()
  end

  @spec list_active_users(map()) :: list()
  def list_active_users(filters \\ %{}) do
    filters
    # Result looks like [%{count: 1678, user: %{email: "alex@gmail.com", id: 1}}]
    |> group_messages_by_user()
    |> Enum.filter(fn r -> r.count > 0 end)
    |> Enum.sort_by(fn r -> r.count end, :desc)
  end

  @spec count_widget_installations(map()) :: number()
  def count_widget_installations(filters \\ %{}) do
    WidgetSetting
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> where([w], not ilike(w.host, "papercups"))
    |> where([w], not ilike(w.host, "localhost"))
    |> select([w], count(w.id))
    |> Repo.one()
  end

  @spec count_new_messages(map()) :: number()
  def count_new_messages(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([m], count(m.id))
    |> Repo.one()
  end

  @spec group_messages_by_account(map()) :: list()
  def group_messages_by_account(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> join(:inner, [m], a in Account, on: m.account_id == a.id)
    |> select([m, a], %{
      account: %{id: a.id, company_name: a.company_name},
      count: count(m.account_id)
    })
    |> group_by([m, a], [m.account_id, a.id])
    |> order_by([m], desc: count(m.account_id))
    |> Repo.all()
  end

  @spec group_messages_by_user(map()) :: list()
  def group_messages_by_user(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> join(:inner, [m], u in User, on: m.user_id == u.id)
    |> select([m, u], %{
      user: %{id: u.id, email: u.email},
      count: count(m.user_id)
    })
    |> group_by([m, u], [m.user_id, u.id])
    |> order_by([m], desc: count(m.user_id))
    |> Repo.all()
  end

  @spec group_messages_by_source(map()) :: list()
  def group_messages_by_source(filters \\ %{}) do
    Message
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([m], %{source: m.source, count: count(m.id)})
    |> group_by([m], [m.source])
    |> order_by([m], desc: count(m.id))
    |> Repo.all()
  end

  @spec count_new_conversations(map()) :: number()
  def count_new_conversations(filters \\ %{}) do
    Conversation
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([c], count(c.id))
    |> Repo.one()
  end

  @spec group_conversations_by_account(map()) :: list()
  def group_conversations_by_account(filters \\ %{}) do
    Conversation
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> join(:inner, [c], a in Account, on: c.account_id == a.id)
    |> select([c, a], %{
      account: %{id: a.id, company_name: a.company_name},
      count: count(c.account_id)
    })
    |> group_by([c, a], [c.account_id, a.id])
    |> order_by([c], desc: count(c.account_id))
    |> Repo.all()
  end

  @spec group_conversations_by_source(map()) :: list()
  def group_conversations_by_source(filters \\ %{}) do
    Conversation
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([c], %{source: c.source, count: count(c.id)})
    |> group_by([c], [c.source])
    |> order_by([c], desc: count(c.id))
    |> Repo.all()
  end

  def count_new_customers(filters \\ %{}) do
    Customer
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([c], count(c.id))
    |> Repo.one()
  end

  @spec group_customers_by_account(map()) :: list()
  def group_customers_by_account(filters \\ %{}) do
    Customer
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> join(:inner, [c], a in Account, on: c.account_id == a.id)
    |> select([c, a], %{
      account: %{id: a.id, company_name: a.company_name},
      count: count(c.account_id)
    })
    |> group_by([c, a], [c.account_id, a.id])
    |> order_by([c], desc: count(c.account_id))
    |> Repo.all()
  end

  @spec group_customers_by_host(map()) :: list()
  def group_customers_by_host(filters \\ %{}) do
    Customer
    |> where(^filter_where(filters))
    |> exclude_admin_account()
    |> select([c], %{host: c.host, count: count(c.id)})
    |> group_by([c], [c.host])
    |> order_by([c], desc: count(c.id))
    |> Repo.all()
  end

  @spec count_new_integrations(map()) :: map()
  def count_new_integrations(filters \\ %{}) do
    github =
      GithubAuthorization
      |> where(^filter_where(filters))
      |> exclude_admin_account()
      |> select([a], count(a.id))
      |> Repo.one()

    google =
      GoogleAuthorization
      |> where(^filter_where(filters))
      |> exclude_admin_account()
      |> select([a], count(a.id))
      |> Repo.one()

    mattermost =
      MattermostAuthorization
      |> where(^filter_where(filters))
      |> exclude_admin_account()
      |> select([a], count(a.id))
      |> Repo.one()

    slack =
      SlackAuthorization
      |> where(^filter_where(filters))
      |> exclude_admin_account()
      |> select([a], count(a.id))
      |> Repo.one()

    twilio =
      TwilioAuthorization
      |> where(^filter_where(filters))
      |> exclude_admin_account()
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
end
