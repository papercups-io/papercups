defmodule ChatApi.Files do
  @moduledoc """
  The Files context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.Files.FileUpload

  @spec get_file!(binary()) :: FileUpload.t()
  def get_file!(id), do: Repo.get!(FileUpload, id)

  @spec create_file(map()) :: {:ok, FileUpload.t()} | {:error, Ecto.Changeset.t()}
  def create_file(attrs \\ %{}) do
    %FileUpload{}
    |> FileUpload.changeset(attrs)
    |> Repo.insert()
  end

  @spec delete_file(FileUpload.t()) :: {:ok, FileUpload.t()} | {:error, Ecto.Changeset.t()}
  def delete_file(%FileUpload{} = file) do
    Repo.delete(file)
  end
end
