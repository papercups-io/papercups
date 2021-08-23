defmodule ChatApi.Broadcasts do
  @moduledoc """
  The Broadcasts context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Broadcasts.Broadcast

  @spec list_broadcasts(binary(), map()) :: [Broadcast.t()]
  def list_broadcasts(account_id, filters \\ %{}) do
    Broadcast
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_broadcast!(binary()) :: Broadcast.t()
  def get_broadcast!(id), do: Repo.get!(Broadcast, id)

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
