defmodule ChatApi.Google do
  @moduledoc """
  The Google context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Google.GoogleAuthorization

  @spec list_google_authorizations() :: [GoogleAuthorization.t()]
  def list_google_authorizations do
    Repo.all(GoogleAuthorization)
  end

  @spec get_google_authorization!(binary()) :: GoogleAuthorization.t()
  def get_google_authorization!(id), do: Repo.get!(GoogleAuthorization, id)

  @spec create_google_authorization(map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_google_authorization(attrs \\ %{}) do
    %GoogleAuthorization{}
    |> GoogleAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_google_authorization(GoogleAuthorization.t(), map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_google_authorization(%GoogleAuthorization{} = google_authorization, attrs) do
    google_authorization
    |> GoogleAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_google_authorization(GoogleAuthorization.t()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_google_authorization(%GoogleAuthorization{} = google_authorization) do
    Repo.delete(google_authorization)
  end

  @spec change_google_authorization(GoogleAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_google_authorization(%GoogleAuthorization{} = google_authorization, attrs \\ %{}) do
    GoogleAuthorization.changeset(google_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: GoogleAuthorization.t() | nil
  def get_authorization_by_account(account_id, filters \\ %{}) do
    GoogleAuthorization
    |> where(account_id: ^account_id)
    |> where(^filter_where(filters))
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec create_or_update_authorization(binary(), map()) ::
          {:ok, GoogleAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(account_id, params) do
    existing = get_authorization_by_account(account_id, params)

    if existing do
      update_google_authorization(existing, params)
    else
      create_google_authorization(params)
    end
  end

  # Pulled from https://hexdocs.pm/ecto/dynamic-queries.html#building-dynamic-queries
  @spec filter_where(map) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:client, value}, dynamic ->
        dynamic([g], ^dynamic and g.client == ^value)

      {:scope, value}, dynamic ->
        dynamic([g], ^dynamic and g.scope == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
