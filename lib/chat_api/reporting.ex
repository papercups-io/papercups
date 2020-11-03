defmodule ChatApi.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false

  alias ChatApi.{
    Repo,
    Conversations.Conversation,
    Messages.Message,
    Users.User,
    Customers.Customer
  }

  @type aggregate_by_date() :: %{date: binary(), count: integer()}
  @type aggregate_by_user() :: %{user: %{id: integer(), email: binary()}, count: integer()}
  @type aggregate_by_weekday() :: %{weekday: binary(), average: float(), total: integer()}
  @type aggregate_by_field() :: %{field: binary(), count: integer()}

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

  @spec count_messages_by_weekday(binary(), map()) :: [aggregate_by_weekday()]
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

  defp count_grouped_by_date(query, field \\ :inserted_at) do
    query
    |> group_by([r], fragment("date(?)", field(r, ^field)))
    |> select([r], %{date: fragment("date(?)", field(r, ^field)), count: count(r.id)})
    |> order_by([r], asc: fragment("date(?)", field(r, ^field)))
  end

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
