defmodule ChatApi.Inboxes do
  @moduledoc """
  The Inboxes context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Inboxes.{Inbox, InboxMember}

  @spec list_inboxes(binary(), map()) :: [Inbox.t()]
  def list_inboxes(account_id, filters \\ %{}) do
    Inbox
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec count_inboxes(binary(), map()) :: number()
  def count_inboxes(account_id, filters \\ %{}) do
    Inbox
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> select([f], count(f.id))
    |> Repo.one()
  end

  @spec has_inboxes?(binary()) :: boolean()
  def has_inboxes?(account_id),
    do: count_inboxes(account_id) > 0

  @spec get_inbox!(binary()) :: Inbox.t()
  def get_inbox!(id), do: Repo.get!(Inbox, id)

  @spec create_inbox(map()) ::
          {:ok, Inbox.t()} | {:error, Ecto.Changeset.t()}
  def create_inbox(attrs \\ %{}) do
    %Inbox{}
    |> Inbox.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_inbox(Inbox.t(), map()) ::
          {:ok, Inbox.t()} | {:error, Ecto.Changeset.t()}
  def update_inbox(%Inbox{} = inbox, attrs) do
    inbox
    |> Inbox.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_inbox(Inbox.t()) ::
          {:ok, Inbox.t()} | {:error, Ecto.Changeset.t()}
  def delete_inbox(%Inbox{} = inbox) do
    Repo.delete(inbox)
  end

  @spec change_inbox(Inbox.t(), map()) :: Ecto.Changeset.t()
  def change_inbox(%Inbox{} = inbox, attrs \\ %{}) do
    Inbox.changeset(inbox, attrs)
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:name, value}, dynamic ->
        dynamic([r], ^dynamic and r.name == ^value)

      {:description, value}, dynamic ->
        dynamic([r], ^dynamic and r.description == ^value)

      {:is_primary, value}, dynamic ->
        dynamic([r], ^dynamic and r.is_primary == ^value)

      {:is_private, value}, dynamic ->
        dynamic([r], ^dynamic and r.is_private == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  @spec list_inbox_members(binary()) :: [InboxMember.t()]
  def list_inbox_members(inbox_id) do
    InboxMember
    |> where(inbox_id: ^inbox_id)
    |> Repo.all()
  end

  @spec count_inbox_members(binary()) :: number()
  def count_inbox_members(inbox_id) do
    InboxMember
    |> where(inbox_id: ^inbox_id)
    |> select([f], count(f.id))
    |> Repo.one()
  end

  @spec has_inbox_members?(binary()) :: boolean()
  def has_inbox_members?(inbox_id),
    do: count_inbox_members(inbox_id) > 0

  @spec get_inbox_member!(binary()) :: InboxMember.t()
  def get_inbox_member!(id), do: Repo.get!(InboxMember, id)

  @spec create_inbox_member(map()) ::
          {:ok, InboxMember.t()} | {:error, Ecto.Changeset.t()}
  def create_inbox_member(attrs \\ %{}) do
    %InboxMember{}
    |> InboxMember.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_inbox_member(InboxMember.t(), map()) ::
          {:ok, InboxMember.t()} | {:error, Ecto.Changeset.t()}
  def update_inbox_member(%InboxMember{} = inbox_member, attrs) do
    inbox_member
    |> InboxMember.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_inbox_member(InboxMember.t()) ::
          {:ok, InboxMember.t()} | {:error, Ecto.Changeset.t()}
  def delete_inbox_member(%InboxMember{} = inbox_member) do
    Repo.delete(inbox_member)
  end
end
