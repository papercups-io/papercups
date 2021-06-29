defmodule ChatApi.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false

  alias ChatApi.Repo
  alias ChatApi.Workers
  alias ChatApi.Messages.{Message, MessageFile}

  require Logger

  @spec list_messages(binary(), map()) :: [Message.t()]
  def list_messages(account_id, filters \\ %{}) do
    Message
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> preload(:conversation)
    |> Repo.all()
  end

  @spec list_by_conversation(binary(), map(), keyword()) :: [Message.t()]
  def list_by_conversation(conversation_id, filters \\ %{}, opts \\ []) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> where(^filter_where(filters))
    |> handle_order_by(opts[:order_by])
    |> maybe_limit(opts[:limit])
    |> preload([:attachments, :customer, [user: :profile]])
    |> Repo.all()
  end

  @spec handle_order_by(Ecto.Query.t(), keyword() | nil) :: Ecto.Query.t()
  def handle_order_by(query, nil), do: query |> order_by(desc: :inserted_at)
  def handle_order_by(query, order_by), do: query |> order_by(^order_by)

  @spec maybe_limit(Ecto.Query.t(), integer() | nil) :: Ecto.Query.t()
  def maybe_limit(query, nil), do: query
  def maybe_limit(query, limit) when is_integer(limit), do: query |> limit(^limit)

  @spec count_messages_by_account(binary()) :: integer()
  def count_messages_by_account(account_id) do
    query =
      from(m in Message,
        where: m.account_id == ^account_id,
        select: count("*")
      )

    Repo.one(query)
  end

  @spec get_message!(binary()) :: Message.t()
  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload([:attachments, :conversation, :customer, [user: :profile]])
  end

  @spec create_message(map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> after_message_created()
  end

  @spec create_and_fetch!(map()) :: Message.t() | {:error, Ecto.Changeset.t()}
  def create_and_fetch!(attrs \\ %{}) do
    case create_message(attrs) do
      {:ok, message} -> get_message!(message.id)
      error -> error
    end
  end

  @spec update_message(Message.t(), map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_message(Message.t()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @spec change_message(Message.t(), map()) :: Ecto.Changeset.t()
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  @spec create_attachments(Message.t(), [binary()]) :: any()
  def create_attachments(%Message{id: message_id, account_id: account_id}, file_ids) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    changesets =
      Enum.map(file_ids, fn file_id ->
        %{
          message_id: message_id,
          account_id: account_id,
          file_id: file_id,
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(MessageFile, changesets)
  end

  @spec query_most_recent_message(keyword()) :: Ecto.Query.t()
  def query_most_recent_message(opts \\ []) do
    partition_by = Keyword.get(opts, :partition_by, :account_id)
    order_by = Keyword.get(opts, :order_by, desc: :inserted_at)
    preload = Keyword.get(opts, :preload, [])

    # For more info, see https://hexdocs.pm/ecto/Ecto.Query.html#preload/3-preload-queries
    # and https://hexdocs.pm/ecto/Ecto.Query.html#windows/3-window-expressions
    ranking_query =
      from(m in Message,
        select: %{id: m.id, row_number: row_number() |> over(:messages_partition)},
        windows: [
          messages_partition: [partition_by: ^partition_by, order_by: ^order_by]
        ]
      )

    # We just want to query the most recent message
    from(m in Message,
      join: r in subquery(ranking_query),
      on: m.id == r.id and r.row_number <= 1,
      preload: ^preload
    )
  end

  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"customer_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.customer_id == ^value)

      {"user_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.user_id == ^value)

      {"conversation_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.conversation_id == ^value)

      {"account_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.account_id == ^value)

      {"source", value}, dynamic ->
        dynamic([p], ^dynamic and p.source == ^value)

      {"type", value}, dynamic ->
        dynamic([p], ^dynamic and p.type == ^value)

      {"private", value}, dynamic ->
        dynamic([p], ^dynamic and p.private == ^value)

      {"body", value}, dynamic ->
        dynamic([r], ^dynamic and ilike(r.body, ^value))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp after_message_created({:ok, message} = params) do
    %{"id" => message.id}
    |> Workers.MessageCreatedActions.new()
    |> Oban.insert()

    params
  end

  defp after_message_created(params), do: params
end
