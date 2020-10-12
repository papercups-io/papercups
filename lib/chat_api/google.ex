defmodule ChatApi.Google do
  @moduledoc """
  The Google context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Google.GoogleAuthorization

  @spec list_google_authorizations() :: [GoogleAuthorization.t()]
  @doc """
  Returns the list of google_authorizations.

  ## Examples

      iex> list_google_authorizations()
      [%GoogleAuthorization{}, ...]

  """
  def list_google_authorizations do
    Repo.all(GoogleAuthorization)
  end

  @spec get_google_authorization!(binary()) :: GoogleAuthorization.t()
  @doc """
  Gets a single google_authorization.

  Raises `Ecto.NoResultsError` if the Google authorization does not exist.

  ## Examples

      iex> get_google_authorization!(123)
      %GoogleAuthorization{}

      iex> get_google_authorization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_google_authorization!(id), do: Repo.get!(GoogleAuthorization, id)

  @spec create_google_authorization(map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a google_authorization.

  ## Examples

      iex> create_google_authorization(%{field: value})
      {:ok, %GoogleAuthorization{}}

      iex> create_google_authorization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_google_authorization(attrs \\ %{}) do
    %GoogleAuthorization{}
    |> GoogleAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_google_authorization(GoogleAuthorization.t(), map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a google_authorization.

  ## Examples

      iex> update_google_authorization(google_authorization, %{field: new_value})
      {:ok, %GoogleAuthorization{}}

      iex> update_google_authorization(google_authorization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_google_authorization(%GoogleAuthorization{} = google_authorization, attrs) do
    google_authorization
    |> GoogleAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_google_authorization(GoogleAuthorization.t()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a google_authorization.

  ## Examples

      iex> delete_google_authorization(google_authorization)
      {:ok, %GoogleAuthorization{}}

      iex> delete_google_authorization(google_authorization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_google_authorization(%GoogleAuthorization{} = google_authorization) do
    Repo.delete(google_authorization)
  end

  @spec change_google_authorization(GoogleAuthorization.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking google_authorization changes.

  ## Examples

      iex> change_google_authorization(google_authorization)
      %Ecto.Changeset{data: %GoogleAuthorization{}}

  """
  def change_google_authorization(%GoogleAuthorization{} = google_authorization, attrs \\ %{}) do
    GoogleAuthorization.changeset(google_authorization, attrs)
  end

  @spec get_authorization_by_account(binary()) :: GoogleAuthorization.t() | nil
  def get_authorization_by_account(account_id) do
    GoogleAuthorization
    |> where(account_id: ^account_id)
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec create_or_update_authorization(binary(), map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(account_id, params) do
    existing = get_authorization_by_account(account_id)

    if existing do
      update_google_authorization(existing, params)
    else
      create_google_authorization(params)
    end
  end
end
