defmodule ChatApi.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.{Repo, Conversations.Conversation, Messages.Message}

  def messages_by_date(account_id) do
    Message
    |> where(account_id: ^account_id)
    |> count_grouped_by_date()
    |> Repo.all()
  end

  def conversations_by_date(account_id) do
    Conversation
    |> where(account_id: ^account_id)
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
