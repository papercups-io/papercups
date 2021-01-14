defmodule ChatApi.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  require Integer

  alias ChatApi.{
    Repo,
    Conversations.Conversation,
    Messages.Message,
    Users.User,
    Customers.Customer
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

  @spec conversation_seconds_to_first_reply_by_date(binary(), map()) :: [map()]
  def conversation_seconds_to_first_reply_by_date(account_id, filters \\ %{}) do
    account_id
    |> list_conversations_with_agent_reply(filters)
    |> Enum.map(fn conv ->
      %{
        date: NaiveDateTime.to_date(conv.inserted_at),
        seconds_to_first_reply: calculate_seconds_to_first_reply(conv)
      }
    end)
    |> Enum.group_by(& &1.date, & &1.seconds_to_first_reply)
    |> Enum.map(fn {date, seconds_to_first_reply_list} ->
      %{
        date: date,
        seconds_to_first_reply_list: seconds_to_first_reply_list,
        average: average(seconds_to_first_reply_list),
        median: median(seconds_to_first_reply_list)
      }
    end)
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

  @spec first_response_time_by_weekday(binary(), map()) :: [aggregate_average_by_weekday()]
  def first_response_time_by_weekday(account_id, filters \\ %{}) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> where([conv], not is_nil(conv.first_replied_at))
    |> average_grouped_by_date()
    |> select_merge([m], %{day: fragment("to_char(date(?), 'Day')", m.inserted_at)})
    |> Repo.all()
    |> Enum.group_by(&String.trim(&1.day))
    |> compute_average_weekday_aggregates()
  end

  @spec count_grouped_by_date(Ecto.Query.t(), atom()) :: Ecto.Query.t()
  defp count_grouped_by_date(query, field \\ :inserted_at) do
    query
    |> group_by([r], fragment("date(?)", field(r, ^field)))
    |> select([r], %{date: fragment("date(?)", field(r, ^field)), count: count(r.id)})
    |> order_by([r], asc: fragment("date(?)", field(r, ^field)))
  end

  # TODO: some duplication here with group by date might be good to refactor
  # TODO: clean this up (see comment about `avg` not doing anything below)
  @spec average_grouped_by_date(Ecto.Query.t(), atom()) :: Ecto.Query.t()
  defp average_grouped_by_date(query, field \\ :inserted_at) do
    query
    |> group_by([r], fragment("date(?)", field(r, ^field)))
    |> select([r], %{
      date: fragment("date(?)", field(r, ^field)),
      count: count(r.id),
      # avg doesn't do anything but raises a grouping_error when I remove it...
      response_time: fragment("extract(epoch FROM ?)", avg(r.first_replied_at - r.inserted_at))
    })
    |> order_by([r], asc: fragment("date(?)", field(r, ^field)))
  end

  @spec compute_weekday_aggregates(map()) :: [map()]
  defp compute_weekday_aggregates(grouped) do
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

  @spec compute_average_weekday_aggregates(map()) :: [aggregate_average_by_weekday()]
  defp compute_average_weekday_aggregates(grouped) do
    Enum.map(weekdays(), fn weekday ->
      records = Map.get(grouped, weekday, [])
      total = Enum.reduce(records, 0, fn x, acc -> x.response_time + acc end)

      %{
        day: weekday,
        average: total / max(length(records), 1),
        unit: :seconds
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
end
