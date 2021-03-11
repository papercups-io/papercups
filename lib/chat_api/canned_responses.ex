defmodule ChatApi.CannedResponses do
  @moduledoc """
  The CannedResponses context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.CannedResponses.CannedResponse

  @doc """
  Returns the list of canned_responses.

  ## Examples

      iex> list_canned_responses()
      [%CannedResponse{}, ...]

  """
  def list_canned_responses do
    Repo.all(CannedResponse)
  end

  def list_canned_responses(account_id) do
    CannedResponse |> where(account_id: ^account_id) |> Repo.all()
  end

  @doc """
  Gets a single canned_response.

  Raises `Ecto.NoResultsError` if the Canned response does not exist.

  ## Examples

      iex> get_canned_response!(123)
      %CannedResponse{}

      iex> get_canned_response!(456)
      ** (Ecto.NoResultsError)

  """
  def get_canned_response!(id), do: Repo.get!(CannedResponse, id)

  @doc """
  Creates a canned_response.

  ## Examples

      iex> create_canned_response(%{field: value})
      {:ok, %CannedResponse{}}

      iex> create_canned_response(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_canned_response(attrs \\ %{}) do
    %CannedResponse{}
    |> CannedResponse.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a canned_response.

  ## Examples

      iex> update_canned_response(canned_response, %{field: new_value})
      {:ok, %CannedResponse{}}

      iex> update_canned_response(canned_response, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_canned_response(%CannedResponse{} = canned_response, attrs) do
    canned_response
    |> CannedResponse.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a canned_response.

  ## Examples

      iex> delete_canned_response(canned_response)
      {:ok, %CannedResponse{}}

      iex> delete_canned_response(canned_response)
      {:error, %Ecto.Changeset{}}

  """
  def delete_canned_response(%CannedResponse{} = canned_response) do
    Repo.delete(canned_response)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking canned_response changes.

  ## Examples

      iex> change_canned_response(canned_response)
      %Ecto.Changeset{data: %CannedResponse{}}

  """
  def change_canned_response(%CannedResponse{} = canned_response, attrs \\ %{}) do
    CannedResponse.changeset(canned_response, attrs)
  end
end
