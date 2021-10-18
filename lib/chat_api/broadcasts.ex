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
    |> where(^filter_broadcasts_where(filters))
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

  @spec count_broadcast_customers(binary(), map()) :: number()
  def count_broadcast_customers(broadcast_id, filters \\ %{}) do
    BroadcastCustomer
    |> where(broadcast_id: ^broadcast_id)
    |> where(^filter_broadcast_customers_where(filters))
    |> select([b], count(b.id))
    |> Repo.one()
  end

  def unstarted?(%Broadcast{state: "unstarted"}), do: true
  def unstarted?(_), do: false

  def finished?(%Broadcast{id: broadcast_id}) do
    count_broadcast_customers(broadcast_id, %{state: "unsent"}) == 0
  end

  @spec update_broadcast_customer(BroadcastCustomer.t(), map()) ::
          {:ok, BroadcastCustomer.t()} | {:error, Ecto.Changeset.t()}
  def update_broadcast_customer(%BroadcastCustomer{} = broadcast_customer, attrs) do
    broadcast_customer
    |> BroadcastCustomer.changeset(attrs)
    |> Repo.update()
  end

  @spec update_broadcast_customer(Broadcast.t(), Customer.t(), map()) ::
          {:ok, BroadcastCustomer.t()} | {:error, Ecto.Changeset.t()}
  def update_broadcast_customer(%Broadcast{id: broadcast_id}, %Customer{id: customer_id}, attrs) do
    update_broadcast_customer(broadcast_id, customer_id, attrs)
  end

  @spec update_broadcast_customer(binary(), binary(), map()) ::
          {:ok, Broadcast.t()} | {:error, Ecto.Changeset.t()}
  def update_broadcast_customer(broadcast_id, customer_id, attrs)
      when is_binary(broadcast_id) and is_binary(customer_id) do
    BroadcastCustomer
    |> where(broadcast_id: ^broadcast_id)
    |> where(customer_id: ^customer_id)
    |> Repo.one!()
    |> BroadcastCustomer.changeset(attrs)
    |> Repo.update()
  end

  @spec list_broadcast_customers(Broadcast.t()) :: [Customer.t()]
  def list_broadcast_customers(
        %Broadcast{
          id: broadcast_id,
          account_id: account_id
        },
        filters \\ %{}
      ) do
    Customer
    |> join(:left, [c], b in assoc(c, :broadcast_customers), as: :broadcast_customers)
    |> where(
      [c, broadcast_customers: b],
      b.broadcast_id == ^broadcast_id and c.account_id == ^account_id
    )
    |> where(^filter_customers_where(filters))
    |> filter_broadcast_customers_by_state(filters)
    |> Repo.all()
  end

  def filter_broadcast_customers_by_state(query, %{state: state}) do
    query |> where([broadcast_customers: b], b.state == ^state)
  end

  def filter_broadcast_customers_by_state(query, _), do: query

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

  @spec remove_broadcast_customers(Broadcast.t()) :: {:ok, any()} | {:error, any()}
  def remove_broadcast_customers(
        %Broadcast{id: broadcast_id, account_id: account_id},
        filters \\ %{}
      ) do
    BroadcastCustomer
    |> where(account_id: ^account_id)
    |> where(broadcast_id: ^broadcast_id)
    |> where(^filter_broadcast_customers_where(filters))
    |> Repo.delete_all()
  end

  @spec set_broadcast_customers(Broadcast.t(), [binary()]) :: {any, nil | list}
  def set_broadcast_customers(broadcast, customer_ids \\ []) do
    remove_broadcast_customers(broadcast, %{state: "unsent"})
    add_broadcast_customers(broadcast, customer_ids)
  end

  @spec upsert_broadcast_customers(Broadcast.t(), [binary()]) :: {any, nil | list}
  def upsert_broadcast_customers(broadcast, customer_ids \\ []) do
    existing_customer_ids = broadcast |> list_broadcast_customers() |> Enum.map(& &1.id)
    new_customer_ids = Enum.reject(customer_ids, &Enum.member?(existing_customer_ids, &1))

    add_broadcast_customers(broadcast, new_customer_ids)
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

  defp filter_broadcasts_where(params) do
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

  defp filter_broadcast_customers_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:broadcast_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.broadcast_id == ^value)

      {:state, value}, dynamic ->
        dynamic([r], ^dynamic and r.state == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp filter_customers_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:customer_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.id == ^value)

      {:customer_ids, list}, dynamic when is_list(list) ->
        dynamic([r], ^dynamic and r.id in ^list)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
