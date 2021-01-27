defmodule ChatApi.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false

  alias ChatApi.Repo
  alias ChatApi.Messages.Message

  require Logger

  @spec list_messages(binary()) :: [Message.t()]
  def list_messages(account_id) do
    Message |> where(account_id: ^account_id) |> preload(:conversation) |> Repo.all()
  end

  @spec list_by_conversation(binary(), binary(), keyword()) :: [Message.t()]
  def list_by_conversation(conversation_id, account_id, limit: limit) do
    Message
    |> where(account_id: ^account_id, conversation_id: ^conversation_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload([:uploads, :customer, [user: :profile]])
    |> Repo.all()
  end

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
    |> Repo.preload([:uploads, :conversation, :customer, [user: :profile]])
  end

  @spec create_message(map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
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
end
