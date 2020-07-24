defmodule ChatApi.Conversations do
  @moduledoc """
  The Conversations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Conversations.Conversation

  @doc """
  Returns the list of conversations.

  ## Examples

      iex> list_conversations()
      [%Conversation{}, ...]

  """
  def list_conversations do
    Conversation |> Repo.all() |> Repo.preload([:customer, :messages])
  end

  def list_conversations_by_account(nil, _) do
    # TODO: raise an exception if nil account is passed in?
    []
  end

  def list_conversations_by_account(account_id, params) do
    Conversation
    |> where(account_id: ^account_id)
    |> where(^filter_where(params))
    |> order_by(desc: :inserted_at)
    |> preload([:customer, :messages])
    |> Repo.all()
  end

  def list_conversations_by_account(account_id) do
    list_conversations_by_account(account_id, %{})
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
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

  def find_by_customer(customer_id, account_id) do
    query =
      from(c in Conversation,
        where: c.customer_id == ^customer_id and c.account_id == ^account_id,
        select: c,
        order_by: [desc: :inserted_at],
        preload: [:customer, :messages]
      )

    Repo.all(query)
  end

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
    Conversation |> Repo.get!(id) |> Repo.preload([:messages, :customer])
  end

  def get_conversation(id) do
    Conversation |> Repo.get(id)
  end

  def get_conversation_with!(id, preloaded) do
    Conversation |> Repo.get!(id) |> Repo.preload(preloaded)
  end

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

  def mark_conversation_read(%Conversation{} = conversation) do
    update_conversation(conversation, %{read: true})
  end

  def mark_conversation_read(conversation_id) do
    conversation = get_conversation!(conversation_id)

    mark_conversation_read(conversation)
  end

  def mark_conversation_unread(%Conversation{} = conversation) do
    update_conversation(conversation, %{read: false})
  end

  def mark_conversation_unread(conversation_id) do
    conversation = get_conversation!(conversation_id)

    mark_conversation_unread(conversation)
  end

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

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

      iex> change_conversation(conversation)
      %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end
end
