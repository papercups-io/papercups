defmodule ChatApi.Conversations.Query do
  import Ecto.Query, warn: false

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message

  def query_by_account(account_id, attrs) do
    Conversation
    |> join(
      :left_lateral,
      [c],
      f in fragment(
        "SELECT id FROM messages WHERE conversation_id = ? ORDER BY sent_at DESC LIMIT 1",
        c.id
      )
    )
    |> join(:left, [c, f], m in Message, on: m.id == f.id)
    |> where(account_id: ^account_id)
    |> where(^filter_where(attrs))
    |> where([c], is_nil(c.archived_at))
    |> order_by([c, f, m], desc: m.sent_at)
    |> preload([c, f, m], [:customer, messages: {m, user: :profile}])
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  def filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"status", value}, dynamic ->
        dynamic([p], ^dynamic and p.status == ^value)

      {"priority", value}, dynamic ->
        dynamic([p], ^dynamic and p.priority == ^value)

      {"assignee_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.assignee_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
