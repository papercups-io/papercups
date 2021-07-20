defmodule ChatApi.Mentions do
  @moduledoc """
  The Mentions context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Mentions.Mention

  @spec list_mentions(binary(), map()) :: [Mention.t()]
  def list_mentions(account_id, filters \\ %{}) do
    Mention
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> Repo.all()
  end

  @spec get_mention!(binary()) :: Mention.t()
  def get_mention!(id), do: Repo.get!(Mention, id)

  @spec create_mention(map()) :: {:ok, Mention.t()} | {:error, Ecto.Changeset.t()}
  def create_mention(attrs \\ %{}) do
    %Mention{}
    |> Mention.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_mention(Mention.t(), map()) :: {:ok, Mention.t()} | {:error, Ecto.Changeset.t()}
  def update_mention(%Mention{} = mention, attrs) do
    mention
    |> Mention.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_mention(Mention.t()) :: {:ok, Mention.t()} | {:error, Ecto.Changeset.t()}
  def delete_mention(%Mention{} = mention) do
    Repo.delete(mention)
  end

  @spec change_mention(Mention.t(), map()) :: Ecto.Changeset.t()
  def change_mention(%Mention{} = mention, attrs \\ %{}) do
    Mention.changeset(mention, attrs)
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

      {:user_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.user_id == ^value)

      {:conversation_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.conversation_id == ^value)

      {:message_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.message_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
