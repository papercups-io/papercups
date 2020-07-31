defmodule ChatApi.Messages do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Messages.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages(account_id)
      [%Message{}, ...]

  """
  def list_messages(account_id) do
    Message |> where(account_id: ^account_id) |> preload(:conversation) |> Repo.all()
  end

  def count_messages_by_account(account_id) do
    query =
      from(m in Message,
        where: m.account_id == ^account_id,
        select: count("*")
      )

    Repo.one(query)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id) do
    Message |> Repo.get!(id) |> Repo.preload([:conversation, :customer, [user: :profile]])
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
