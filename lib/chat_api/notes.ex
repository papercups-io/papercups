defmodule ChatApi.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Notes.Note

  @spec list_notes_by_account(binary(), map()) :: [Note.t()]
  def list_notes_by_account(account_id, filters) do
    Note
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload([:customer, author: :profile])
  end

  @spec get_note!(binary()) :: Note.t()
  def get_note!(id), do: Repo.get!(Note, id)

  @spec create_note(map()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_note(Note.t(), map()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_note(Note.t()) :: {:ok, Note.t()} | {:error, Ecto.Changeset.t()}
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @spec change_note(Note.t(), map()) :: Ecto.Changeset.t()
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map()) :: %Ecto.Query.DynamicExpr{}
  defp filter_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {"customer_id", value}, dynamic ->
        dynamic([n], ^dynamic and n.customer_id == ^value)

      {"account_id", value}, dynamic ->
        dynamic([n], ^dynamic and n.account_id == ^value)

      {"author_id", value}, dynamic ->
        dynamic([n], ^dynamic and n.author_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
