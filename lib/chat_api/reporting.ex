defmodule ChatApi.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Repo, Conversations.Conversation, Messages.Message, Users.User}

  def messages_by_date(account_id) do
    Message
    |> where(account_id: ^account_id)
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def messages_by_date(account_id, from_date, to_date) do
    Message
    |> where(account_id: ^account_id)
    |> where([m], m.inserted_at > ^from_date and m.inserted_at < ^to_date)
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

  def conversations_by_date(account_id) do
    Conversation
    |> where(account_id: ^account_id)
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def conversations_by_date(account_id, from_date, to_date) do
    Conversation
    |> where(account_id: ^account_id)
    |> where([c], c.inserted_at > ^from_date and c.inserted_at < ^to_date)
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def count_grouped_by_date(query, field \\ :inserted_at) do
    query
    |> group_by([r], fragment("date(?)", field(r, ^field)))
    |> select([r], %{date: fragment("date(?)", field(r, ^field)), count: count(r.id)})
    |> order_by([r], asc: fragment("date(?)", field(r, ^field)))
  end
end
