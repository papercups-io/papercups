defmodule ChatApi.Lambdas do
  @moduledoc """
  The Lambdas context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Lambdas.Lambda

  @spec list_lambdas(binary(), map()) :: [Lambda.t()]
  def list_lambdas(account_id, filters \\ %{}) do
    Lambda
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_lambda!(binary()) :: Lambda.t()
  def get_lambda!(id), do: Repo.get!(Lambda, id)

  @spec create_lambda(map()) :: {:ok, Lambda.t()} | {:error, Ecto.Changeset.t()}
  def create_lambda(attrs \\ %{}) do
    %Lambda{}
    |> Lambda.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_lambda(Lambda.t(), map()) :: {:ok, Lambda.t()} | {:error, Ecto.Changeset.t()}
  def update_lambda(%Lambda{} = lambda, attrs) do
    lambda
    |> Lambda.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_lambda(Lambda.t()) :: {:ok, Lambda.t()} | {:error, Ecto.Changeset.t()}
  def delete_lambda(%Lambda{} = lambda) do
    Repo.delete(lambda)
  end

  @spec change_lambda(Lambda.t(), map()) :: Ecto.Changeset.t()
  def change_lambda(%Lambda{} = lambda, attrs \\ %{}) do
    Lambda.changeset(lambda, attrs)
  end

  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    params
    |> Map.new(fn
      {k, v} when is_binary(k) -> {String.to_existing_atom(k), v}
      {k, v} when is_atom(k) -> {k, v}
    end)
    |> Enum.reduce(dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:creator_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.creator_id == ^value)

      {:status, value}, dynamic ->
        dynamic([r], ^dynamic and r.status == ^value)

      {:name, value}, dynamic ->
        dynamic([r], ^dynamic and r.name == ^value)

      {:q, ""}, dynamic ->
        dynamic

      {:q, query}, dynamic ->
        value = "%" <> query <> "%"

        dynamic(
          [r],
          ^dynamic and
            (ilike(r.name, ^value) or ilike(r.description, ^value))
        )

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
