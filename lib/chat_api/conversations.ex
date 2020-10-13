defmodule ChatApi.Conversations do
  @moduledoc """
  The Conversations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Tags.{Tag, ConversationTag}

  @spec list_conversations() :: [Conversation.t()]
  @doc """
  Returns the list of conversations.

  ## Examples

      iex> list_conversations()
      [%Conversation{}, ...]

  """
  def list_conversations do
    Conversation |> Repo.all() |> Repo.preload([:customer, :messages])
  end

  @spec list_conversations_by_account(binary(), map()) :: [Conversation.t()]
  def list_conversations_by_account(nil, _) do
    # TODO: raise an exception if nil account is passed in?
    []
  end

  def list_conversations_by_account(account_id, params) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(params))
    |> order_by(desc: :inserted_at)
    |> preload([:customer, [messages: [user: :profile]]])
    |> Repo.all()
  end

  @spec list_conversations_by_account(binary()) :: [Conversation.t()]
  def list_conversations_by_account(account_id) do
    list_conversations_by_account(account_id, %{})
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: Ecto.Query.DynamicExpr.t()
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
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

  @spec find_by_customer(binary(), binary()) :: [Conversation.t()]
  def find_by_customer(customer_id, account_id) do
    query =
      from(c in Conversation,
        where: c.customer_id == ^customer_id and c.account_id == ^account_id,
        select: c,
        order_by: [desc: :inserted_at],
        preload: [:customer, messages: [user: :profile]]
      )

    Repo.all(query)
  end

  @spec get_conversation!(binary()) :: Conversation.t()
  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.

  ## Examples

      iex> get_conversation!(123)
      %Conversation{}

      iex> get_conversation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation!(id) do
    Conversation
    |> Repo.get!(id)
    |> Repo.preload([:customer, :tags, messages: [user: :profile]])
  end

  @spec get_conversation(binary()) :: Conversation.t() | nil
  def get_conversation(id) do
    Conversation |> Repo.get(id)
  end

  @spec get_conversation_with!(binary(), atom() | list()) :: Conversation.t()
  def get_conversation_with!(id, preloaded) do
    Conversation |> Repo.get!(id) |> Repo.preload(preloaded)
  end

  @spec get_conversation_customer!(binary()) :: Customer.t()
  def get_conversation_customer!(conversation_id) do
    conversation_id |> get_conversation_with!(:customer) |> Map.get(:customer)
  end

  @spec create_conversation(map()) :: {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a conversation.

  ## Examples

      iex> create_conversation(%{field: value})
      {:ok, %Conversation{}}

      iex> create_conversation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_test_conversation(map()) :: {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def create_test_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.test_changeset(attrs)
    |> Repo.insert()
  end

  @spec update_conversation(Conversation.t(), map()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a conversation.

  ## Examples

      iex> update_conversation(conversation, %{field: new_value})
      {:ok, %Conversation{}}

      iex> update_conversation(conversation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
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

  @spec delete_conversation(Conversation.t()) ::
          {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a conversation.

  ## Examples

      iex> delete_conversation(conversation)
      {:ok, %Conversation{}}

      iex> delete_conversation(conversation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @spec change_conversation(Conversation.t(), map) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

      iex> change_conversation(conversation)
      %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
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
end
