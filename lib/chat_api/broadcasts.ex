defmodule ChatApi.Broadcasts do
  @moduledoc """
  The Broadcasts context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Broadcasts.{Broadcast, BroadcastCustomer}
  alias ChatApi.Customers.Customer

  @spec list_broadcasts(binary(), map()) :: [Broadcast.t()]
  def list_broadcasts(account_id, filters \\ %{}) do
    Broadcast
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_broadcast!(binary(), list()) :: Broadcast.t()
  def get_broadcast!(id, preloaded \\ []) do
    Broadcast |> Repo.get!(id) |> Repo.preload(preloaded)
  end

  @spec create_broadcast(map()) ::
          {:ok, Broadcast.t()} | {:error, Ecto.Changeset.t()}
  def create_broadcast(attrs \\ %{}) do
    %Broadcast{}
    |> Broadcast.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_broadcast(Broadcast.t(), map()) ::
          {:ok, Broadcast.t()} | {:error, Ecto.Changeset.t()}
  def update_broadcast(%Broadcast{} = broadcast, attrs) do
    broadcast
    |> Broadcast.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_broadcast(Broadcast.t()) ::
          {:ok, Broadcast.t()} | {:error, Ecto.Changeset.t()}
  def delete_broadcast(%Broadcast{} = broadcast) do
    Repo.delete(broadcast)
  end

  @spec change_broadcast(Broadcast.t(), map()) :: Ecto.Changeset.t()
  def change_broadcast(%Broadcast{} = broadcast, attrs \\ %{}) do
    Broadcast.changeset(broadcast, attrs)
  end

  @spec list_broadcast_customers(Broadcast.t()) :: [Customer.t()]
  def list_broadcast_customers(%Broadcast{id: broadcast_id, account_id: account_id}) do
    Customer
    |> join(:left, [c], b in assoc(c, :broadcast_customers))
    |> where([c, b], b.broadcast_id == ^broadcast_id and c.account_id == ^account_id)
    |> Repo.all()
  end

  @spec add_broadcast_customers(Broadcast.t(), [binary()]) :: {any, nil | list}
  def add_broadcast_customers(
        %Broadcast{
          id: broadcast_id,
          account_id: account_id
        },
        customer_ids \\ []
      ) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)

    Repo.insert_all(
      BroadcastCustomer,
      Enum.map(customer_ids, fn customer_id ->
        %{
          customer_id: customer_id,
          account_id: account_id,
          broadcast_id: broadcast_id,
          inserted_at: now,
          updated_at: now
        }
      end),
      on_conflict: :nothing
    )
  end

  @spec remove_broadcast_customer(Broadcast.t(), any) :: {:ok, any()} | {:error, any()}
  def remove_broadcast_customer(%Broadcast{id: broadcast_id, account_id: account_id}, customer_id) do
    record =
      BroadcastCustomer
      |> where(account_id: ^account_id)
      |> where(broadcast_id: ^broadcast_id)
      |> where(customer_id: ^customer_id)
      |> Repo.one!()

    case record do
      nil -> {:error, :not_found}
      %BroadcastCustomer{} -> Repo.delete(record)
    end
  end

  defp filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:name, value}, dynamic ->
        dynamic([r], ^dynamic and r.name == ^value)

      {:state, value}, dynamic ->
        dynamic([r], ^dynamic and r.state == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
