defmodule ChatApi.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Repo, Conversations.Conversation, Messages.Message, Users.User}

  # TODO: filter by records created between a given `from_date` and `to_date`
  def messages_by_date(account_id) do
    Message
    |> where(account_id: ^account_id)
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def count_messages_per_user(account_id) do
    Message
    |> where(account_id: ^account_id)
    |> join(:inner, [m], u in User, on: m.user_id == u.id)
    |> select([m, u], %{user: %{id: u.id, email: u.email}, count: count(m.user_id)})
    |> group_by([m, u], [m.user_id, u.id])
    |> Repo.all()
  end

  # TODO: filter by records created between a given `from_date` and `to_date`
  def conversations_by_date(account_id) do
    Conversation
    |> where(account_id: ^account_id)
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def count_sent_messages_by_date() do
    Message
    |> where([message], not is_nil(message.user_id))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def count_received_messages_by_date() do
    Message
    |> where([message], not is_nil(message.customer_id))
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def count_grouped_by_date(query, field \\ :inserted_at) do
    query
    |> group_by([r], fragment("date(?)", field(r, ^field)))
    |> select([r], %{date: fragment("date(?)", field(r, ^field)), count: count(r.id)})
    |> order_by([r], asc: fragment("date(?)", field(r, ^field)))
  end

  def count_messages_by_weekday(account_id) do
    Message
    |> where(account_id: ^account_id)
    |> where([m], not is_nil(m.customer_id))
    |> count_grouped_by_date()
    |> select_merge([m], %{day: fragment("to_char(date(?), 'Day')", m.inserted_at)})
    |> Repo.all()
    |> Enum.group_by(&String.trim(&1.day))
    |> compute_weekday_aggregates()
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

  defp weekdays, do: ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
end
