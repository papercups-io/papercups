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
  alias ChatApi.Tags.{Tag, ConversationTag}

  @spec list_conversations() :: [Conversation.t()]
  def list_conversations do
    Conversation |> Repo.all() |> Repo.preload([:customer, :messages])
  end

  @spec list_conversations_by_account(binary(), map()) :: [Conversation.t()]
  def list_conversations_by_account(nil, _) do
    # TODO: raise an exception if nil account is passed in?
    []
  end

  def list_conversations_by_account(account_id, attrs) do
    Conversation
    |> join(
      :left_lateral,
      [c],
      f in fragment(
        "SELECT inserted_at FROM messages WHERE conversation_id = ? ORDER BY inserted_at DESC LIMIT 1",
        c.id
      )
    )
    |> where(account_id: ^account_id)
    |> where(^filter_where(attrs))
    |> where([c], is_nil(c.archived_at))
    |> order_by([c, f], desc: f)
    |> preload([:customer, messages: [user: :profile]])
    |> Repo.all()
  end

  @spec list_conversations_by_account(binary()) :: [Conversation.t()]
  def list_conversations_by_account(account_id) do
    list_conversations_by_account(account_id, %{})
  end

  @customer_conversations_limit 3

  @spec find_by_customer(binary(), binary()) :: [Conversation.t()]
  def find_by_customer(customer_id, account_id) do
    # NB: this is the method used to fetch conversations for a customer in the widget,
    # so we need to make sure that private messages are excluded from the query.
    messages =
      from m in Message,
        where: m.private == false,
        order_by: m.inserted_at,
        preload: [user: :profile]

    Conversation
    |> where(customer_id: ^customer_id)
    |> where(account_id: ^account_id)
    |> where(status: "open")
    |> where([c], is_nil(c.archived_at))
    |> order_by(desc: :inserted_at)
    |> limit(@customer_conversations_limit)
    |> preload([:customer, messages: ^messages])
    |> Repo.all()
  end

  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.
  """
  @spec get_conversation!(binary()) :: Conversation.t()
  def get_conversation!(id) do
    # TODO: make sure messages are sorted properly?
    Conversation
    |> Repo.get!(id)
    |> Repo.preload([:customer, :tags, messages: [user: :profile]])
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
    |> Repo.preload([:customer, :tags, messages: [user: :profile]])
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
    from c in Conversation,
      join: a in Account,
      on: a.id == c.account_id,
      join:
        last_message in subquery(
          from m in Message,
            group_by: m.conversation_id,
            select: %{
              conversation_id: m.conversation_id,
              most_recently_inserted_at: max(m.inserted_at)
            }
        ),
      on: last_message.conversation_id == c.id,
      where:
        is_nil(c.archived_at) and
          a.subscription_plan == "starter" and c.priority == "not_priority" and
          c.inserted_at < ago(^days, "day") and
          last_message.most_recently_inserted_at < ago(^days, "day")
  end

  @spec query_conversations_closed_for([{:days, number}]) :: Ecto.Query.t()
  def query_conversations_closed_for(days: days) do
    Conversation
    |> where([c], is_nil(c.archived_at))
    |> where(status: "closed")
    |> where([c], c.updated_at < ago(^days, "day"))
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

  @spec list_tags(binary()) :: [Tag.t()]
  def list_tags(id) do
    # TODO: optimize this query
    Conversation
    |> Repo.get(id)
    |> case do
      nil -> []
      found -> found |> Repo.preload(:tags) |> Map.get(:tags)
    end
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

  #####################
  # Private methods
  #####################

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  defp filter_where(attrs) do
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
