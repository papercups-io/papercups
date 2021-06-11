defmodule ChatApi.Lambdas do
  @moduledoc """
  The Lambdas context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Lambdas.Lambda

  @spec list_lambdas(binary(), map()) :: [Issue.t()]
  def list_lambdas(account_id, filters \\ %{}) do
    Lambda
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  def get_lambda!(id), do: Repo.get!(Lambda, id)

  def create_lambda(attrs \\ %{}) do
    %Lambda{}
    |> Lambda.changeset(attrs)
    |> Repo.insert()
  end

  def update_lambda(%Lambda{} = lambda, attrs) do
    lambda
    |> Lambda.changeset(attrs)
    |> Repo.update()
  end

  def delete_lambda(%Lambda{} = lambda) do
    Repo.delete(lambda)
  end

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
