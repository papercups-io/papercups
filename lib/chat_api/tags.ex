defmodule ChatApi.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Tags.Tag

  @spec list_tags(binary()) :: [Tag.t()]
  def list_tags(account_id) do
    Tag |> where(account_id: ^account_id) |> Repo.all()
  end

  @spec get_tag!(binary()) :: Tag.t()
  def get_tag!(id) do
    Tag |> Repo.get!(id)
  end

  @spec create_tag(map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_tag(Tag.t(), map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_tag(Tag.t()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @spec change_tag(Tag.t(), map()) :: Ecto.Changeset.t()
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  @spec list_customers_by_tag(binary()) :: [Customer.t()]
  def list_customers_by_tag(tag_id) do
    Tag
    |> preload(:customers)
    |> Repo.get!(tag_id)
    |> Map.get(:customers)
  end

  @spec list_conversations_by_tag(binary()) :: [Conversation.t()]
  def list_conversations_by_tag(tag_id) do
    Tag
    |> preload(:conversations)
    |> Repo.get!(tag_id)
    |> Map.get(:conversations)
  end
end
