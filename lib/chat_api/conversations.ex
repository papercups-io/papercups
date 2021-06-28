defmodule ChatApi.Conversations do
  @moduledoc """
  The Conversations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message
  alias ChatApi.Tags.ConversationTag

  @spec list_conversations_by_account(binary(), map()) :: [Conversation.t()]
  def list_conversations_by_account(account_id, filters \\ %{}) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> where([c], is_nil(c.archived_at))
    |> filter_by_tag(filters)
    |> order_by_most_recent_message()
    |> preload([:customer, messages: [:attachments, :customer, user: :profile]])
    |> Repo.all()
  end

  @spec list_conversations_by_account_paginated(binary(), map(), Keyword.t()) ::
          Paginator.Page.t()
  def list_conversations_by_account_paginated(
        account_id,
        filters \\ %{},
        pagination_options \\ []
      ) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> where([c], is_nil(c.archived_at))
    |> filter_by_tag(filters)
    |> order_by(desc: :last_activity_at, desc: :id)
    |> preload([:customer, messages: [:attachments, :customer, user: :profile]])
    |> Repo.paginate_with_cursor(
      Keyword.merge(
        [
          include_total_count: true,
          cursor_fields: [last_activity_at: :desc, id: :desc]
        ],
        pagination_options
      )
    )
  end

  @spec list_other_recent_conversations(Conversation.t(), integer(), map()) :: [Conversation.t()]
  def list_other_recent_conversations(
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          customer_id: customer_id
        } = _conversation,
        limit \\ 5,
        filters \\ %{}
      ) do
    messages_query =
      ChatApi.Messages.query_most_recent_message(
        partition_by: :conversation_id,
        order_by: [desc: :inserted_at],
        preload: [:customer, user: :profile]
      )

    Conversation
    |> where(account_id: ^account_id)
    |> where(customer_id: ^customer_id)
    |> where([c], c.id != ^conversation_id)
    |> where(^filter_where(filters))
    |> where([c], is_nil(c.archived_at))
    |> order_by_most_recent_message()
    |> limit(^limit)
    |> preload([:customer, messages: ^messages_query])
    |> Repo.all()
  end

  @spec get_previous_conversation(Conversation.t(), map()) :: Conversation.t() | nil
  def get_previous_conversation(
        %Conversation{
          id: conversation_id,
          inserted_at: inserted_at,
          account_id: account_id,
          customer_id: customer_id
        } = _conversation,
        filters \\ %{}
      ) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(customer_id: ^customer_id)
    |> where([c], c.inserted_at < ^inserted_at)
    |> where([c], c.id != ^conversation_id)
    |> where(^filter_where(filters))
    |> where([c], is_nil(c.archived_at))
    |> order_by_most_recent_message()
    |> preload([:customer, messages: [:attachments, :customer, user: :profile]])
    |> first()
    |> Repo.one()
  end

  # Alternative to `get_previous_conversation/2` above
  @spec get_previous_conversation_id(Conversation.t(), map()) :: binary() | nil
  def get_previous_conversation_id(
        %Conversation{
          id: conversation_id,
          inserted_at: inserted_at,
          account_id: account_id,
          customer_id: customer_id
        } = _conversation,
        filters \\ %{}
      ) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(customer_id: ^customer_id)
    |> where([c], c.inserted_at < ^inserted_at)
    |> where([c], c.id != ^conversation_id)
    |> where(^filter_where(filters))
    |> where([c], is_nil(c.archived_at))
    |> order_by_most_recent_message()
    |> select([:id])
    |> first()
    |> Repo.one()
    |> case do
      %Conversation{id: conversation_id} -> conversation_id
      _ -> nil
    end
  end

  @spec list_forgotten_conversations(binary(), integer()) :: [Conversation.t()]
  def list_forgotten_conversations(account_id, hours \\ 24) do
    ranking_query =
      from(m in Message,
        select: %{id: m.id, row_number: row_number() |> over(:messages_partition)},
        windows: [
          messages_partition: [partition_by: :conversation_id, order_by: [desc: :inserted_at]]
        ]
      )

    messages_query =
      from(m in Message,
        join: r in subquery(ranking_query),
        on: m.id == r.id and r.row_number <= 1
      )

    query =
      from(c in Conversation,
        where: c.status == "open" and c.account_id == ^account_id and is_nil(c.archived_at),
        join: most_recent_messages in subquery(messages_query),
        on: most_recent_messages.conversation_id == c.id,
        on:
          not is_nil(most_recent_messages.customer_id) or
            fragment(
              """
              (?."metadata"->>'is_reminder' = 'true')
              """,
              most_recent_messages
            ),
        on: most_recent_messages.inserted_at < ago(^hours, "hour")
      )

    query
    |> preload([:customer, messages: ^messages_query])
    |> Repo.all()
  end

  @customer_conversations_limit 3

  # Used externally in chat widget
  @spec find_by_customer(binary(), binary()) :: [Conversation.t()]
  def find_by_customer(customer_id, account_id) do
    # NB: this is the method used to fetch conversations for a customer in the widget,
    # so we need to make sure that private messages are excluded from the query.
    messages =
      from(m in Message,
        where: m.private == false,
        order_by: m.inserted_at,
        preload: [:attachments, user: :profile]
      )

    Conversation
    |> where(customer_id: ^customer_id)
    |> where(account_id: ^account_id)
    |> where(source: "chat")
    |> where(status: "open")
    |> where([c], is_nil(c.archived_at))
    |> order_by(desc: :inserted_at)
    |> limit(@customer_conversations_limit)
    |> preload([:customer, messages: ^messages])
    |> Repo.all()
  end

  @spec find_latest_conversation(binary(), map()) :: Conversation.t() | nil
  def find_latest_conversation(account_id, filters) do
    Conversation
    |> where(^filter_where(filters))
    |> where(account_id: ^account_id)
    |> where([c], is_nil(c.archived_at))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  # Used internally in dashboard
  @spec list_recent_by_customer(binary(), binary(), integer()) :: [Conversation.t()]
  def list_recent_by_customer(customer_id, account_id, limit \\ 5) do
    messages_query =
      ChatApi.Messages.query_most_recent_message(
        partition_by: :conversation_id,
        order_by: [desc: :inserted_at],
        preload: [:customer, user: :profile]
      )

    Conversation
    |> where(account_id: ^account_id)
    |> where(customer_id: ^customer_id)
    |> where([c], is_nil(c.archived_at))
    |> order_by_most_recent_message()
    |> limit(^limit)
    |> preload([:customer, messages: ^messages_query])
    |> Repo.all()
  end

  @spec order_by_most_recent_message(Ecto.Query.t()) :: Ecto.Query.t()
  def order_by_most_recent_message(query) do
    # TODO: replace with sorting by `last_activity_at`
    query
    |> join(
      :left_lateral,
      [c],
      f in fragment(
        "SELECT inserted_at FROM messages WHERE conversation_id = ? ORDER BY inserted_at DESC LIMIT 1",
        c.id
      ),
      as: :last_message_created_at
    )
    |> order_by([c, last_message_created_at: l], desc: l)
  end

  @spec get_conversation!(binary()) :: Conversation.t()
  def get_conversation!(id) do
    # TODO: make sure messages are sorted properly?
    Conversation
    |> Repo.get!(id)
    |> Repo.preload([:customer, :tags, messages: [:attachments, :customer, user: :profile]])
  end

  @spec get_conversation(binary()) :: Conversation.t() | nil
  def get_conversation(id) do
    Conversation |> Repo.get(id)
  end

  @spec get_conversation_with(binary(), atom() | list()) :: Conversation.t()
  def get_conversation_with(id, preloaded) do
    Conversation |> Repo.get(id) |> Repo.preload(preloaded)
  end

  @spec get_conversation_with!(binary(), atom() | list()) :: Conversation.t()
  def get_conversation_with!(id, preloaded) do
    Conversation |> Repo.get!(id) |> Repo.preload(preloaded)
  end

  @spec get_conversation_customer!(binary()) :: Customer.t()
  def get_conversation_customer!(conversation_id) do
    conversation_id |> get_conversation_with!(:customer) |> Map.get(:customer)
  end

  @spec get_shared_conversation!(binary(), binary(), binary()) :: Conversation.t()
  def get_shared_conversation!(conversation_id, account_id, customer_id) do
    # TODO: make sure messages are sorted properly?
    Conversation
    |> where(id: ^conversation_id)
    |> where(customer_id: ^customer_id)
    |> where(account_id: ^account_id)
    |> where([c], is_nil(c.archived_at))
    |> Repo.one!()
    |> Repo.preload([:customer, :tags, messages: [:attachments, :customer, user: :profile]])
  end

  @spec create_conversation(map()) :: {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_conversation(Conversation.t(), map()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  @spec skip_update?(Conversation.t(), map()) :: boolean()
  def skip_update?(%Conversation{} = conversation, updates),
    do: Enum.all?(updates, fn {k, v} -> Map.get(conversation, k) == v end)

  @spec should_update?(Conversation.t(), map()) :: boolean()
  def should_update?(%Conversation{} = conversation, updates),
    do: !skip_update?(conversation, updates)

  @spec mark_conversation_read(Conversation.t() | binary()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def mark_conversation_read(%Conversation{} = conversation) do
    update_conversation(conversation, %{read: true})
  end

  def mark_conversation_read(conversation_id) do
    conversation = get_conversation!(conversation_id)

    mark_conversation_read(conversation)
  end

  @spec mark_conversation_unread(Conversation.t() | binary()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def mark_conversation_unread(%Conversation{} = conversation) do
    update_conversation(conversation, %{read: false})
  end

  def mark_conversation_unread(conversation_id) do
    conversation = get_conversation!(conversation_id)

    mark_conversation_unread(conversation)
  end

  @spec get_unseen_agent_messages(binary()) :: [Message.t()]
  def get_unseen_agent_messages(conversation_id) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> where([m], is_nil(m.seen_at))
    |> where([m], not is_nil(m.user_id))
    |> Repo.all()
  end

  @spec mark_agent_messages_as_seen(binary) :: {integer(), nil | [term()]}
  def mark_agent_messages_as_seen(conversation_id) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> where([m], is_nil(m.seen_at))
    |> where([m], not is_nil(m.user_id))
    |> Repo.update_all(set: [seen_at: DateTime.utc_now()])
  end

  @spec has_unseen_messages?(binary()) :: boolean()
  def has_unseen_messages?(conversation_id) do
    query =
      from(m in Message,
        where:
          m.conversation_id == ^conversation_id and is_nil(m.seen_at) and not is_nil(m.user_id),
        select: count("*")
      )

    Repo.one(query) > 0
  end

  @spec archive_conversation(Conversation.t() | binary()) ::
          {:error, Ecto.Changeset.t()} | {:ok, Conversation.t()}
  def archive_conversation(%Conversation{} = conversation) do
    update_conversation(conversation, %{archived_at: DateTime.utc_now()})
  end

  def archive_conversation(conversation_id) do
    conversation = get_conversation!(conversation_id)

    archive_conversation(conversation)
  end

  @spec archive_conversations(Ecto.Query.t()) :: {number, nil}
  def archive_conversations(%Ecto.Query{} = query) do
    Repo.update_all(query, set: [archived_at: DateTime.utc_now()])
  end

  # TODO: I wonder if this should live somewhere else...
  @spec query_free_tier_conversations_inactive_for([{:days, number}]) :: Ecto.Query.t()
  def query_free_tier_conversations_inactive_for(days: days) do
    from(c in Conversation,
      join: a in Account,
      on: a.id == c.account_id,
      join:
        last_message in subquery(
          from(m in Message,
            group_by: m.conversation_id,
            select: %{
              conversation_id: m.conversation_id,
              most_recently_inserted_at: max(m.inserted_at)
            }
          )
        ),
      on: last_message.conversation_id == c.id,
      where:
        is_nil(c.archived_at) and
          a.subscription_plan == "starter" and c.priority == "not_priority" and
          c.inserted_at < ago(^days, "day") and
          last_message.most_recently_inserted_at < ago(^days, "day")
    )
  end

  @spec query_conversations_closed_for([{:days, number}]) :: Ecto.Query.t()
  def query_conversations_closed_for(days: days) do
    Conversation
    |> where([c], is_nil(c.archived_at))
    |> where(status: "closed")
    |> where([c], c.updated_at < ago(^days, "day"))
  end

  @spec query_most_recent_conversation(keyword()) :: Ecto.Query.t()
  def query_most_recent_conversation(opts \\ []) do
    partition_by = Keyword.get(opts, :partition_by, :account_id)
    order_by = Keyword.get(opts, :order_by, desc: :last_activity_at)
    preload = Keyword.get(opts, :preload, [])

    ranking_query =
      from(m in Conversation,
        select: %{id: m.id, row_number: row_number() |> over(:conversations_partition)},
        windows: [
          conversations_partition: [partition_by: ^partition_by, order_by: ^order_by]
        ]
      )

    # We just want to query the most recent conversation
    from(c in Conversation,
      join: r in subquery(ranking_query),
      on: c.id == r.id and r.row_number <= 1,
      preload: ^preload
    )
  end

  @spec delete_conversation(Conversation.t()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @spec change_conversation(Conversation.t(), map) :: Ecto.Changeset.t()
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end

  @spec get_first_message(binary()) :: Message.t() | nil
  def get_first_message(conversation_id) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> order_by(asc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec is_first_message?(binary(), binary()) :: boolean()
  def is_first_message?(conversation_id, message_id) do
    case get_first_message(conversation_id) do
      %Message{id: ^message_id} -> true
      _ -> false
    end
  end

  @spec count_agent_replies(binary()) :: number()
  def count_agent_replies(conversation_id) do
    Message
    |> where(conversation_id: ^conversation_id)
    |> where([m], not is_nil(m.user_id))
    |> select([m], count(m.id))
    |> Repo.one()
  end

  @spec has_agent_replied?(binary()) :: boolean()
  def has_agent_replied?(conversation_id) do
    count_agent_replies(conversation_id) > 0
  end

  @spec get_tag(Conversation.t(), binary()) :: ConversationTag.t() | nil
  def get_tag(%Conversation{id: id, account_id: account_id} = _conversation, tag_id) do
    ConversationTag
    |> where(account_id: ^account_id, conversation_id: ^id, tag_id: ^tag_id)
    |> Repo.one()
  end

  @spec add_tag(Conversation.t(), binary()) ::
          {:ok, ConversationTag.t()} | {:error, Ecto.Changeset.t()}
  def add_tag(%Conversation{id: id, account_id: account_id} = conversation, tag_id) do
    case get_tag(conversation, tag_id) do
      nil ->
        %ConversationTag{}
        |> ConversationTag.changeset(%{
          conversation_id: id,
          tag_id: tag_id,
          account_id: account_id
        })
        |> Repo.insert()

      tag ->
        {:ok, tag}
    end
  end

  @spec remove_tag(Conversation.t(), binary()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def remove_tag(%Conversation{} = conversation, tag_id) do
    conversation
    |> get_tag(tag_id)
    |> Repo.delete()
  end

  @spec filter_by_tag(Ecto.Query.t(), map()) :: Ecto.Query.t()
  def filter_by_tag(query, %{"tag_id" => tag_id}) when not is_nil(tag_id) do
    query
    |> join(:left, [c], t in assoc(c, :tags), as: :tags)
    |> where([_c, tags: t], t.id == ^tag_id)
  end

  def filter_by_tag(query, _filters), do: query

  @spec mark_activity(String.t()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def mark_activity(id) do
    %Conversation{id: id}
    |> Conversation.last_activity_changeset(%{
      last_activity_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @spec find_or_create_by_customer(String.t(), String.t(), map()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create_by_customer(account_id, customer_id, attrs \\ %{}) do
    params = Map.merge(attrs, %{"customer_id" => customer_id, "account_id" => account_id})

    case find_latest_conversation(account_id, params) do
      nil -> create_conversation(params)
      conversation -> {:ok, conversation}
    end
  end

  #####################
  # Private methods
  #####################

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: %Ecto.Query.DynamicExpr{}
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"status", value}, dynamic ->
        dynamic([p], ^dynamic and p.status == ^value)

      {"priority", value}, dynamic ->
        dynamic([p], ^dynamic and p.priority == ^value)

      {"assignee_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.assignee_id == ^value)

      {"customer_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.customer_id == ^value)

      {"account_id", value}, dynamic ->
        dynamic([p], ^dynamic and p.account_id == ^value)

      {"source", value}, dynamic ->
        dynamic([p], ^dynamic and p.source == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
