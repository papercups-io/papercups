defmodule ChatApi.Github do
  @moduledoc """
  The Github context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Github.GithubAuthorization

  @spec list_github_authorizations() :: [GithubAuthorization.t()]
  def list_github_authorizations() do
    Repo.all(GithubAuthorization)
  end

  @spec get_github_authorization!(binary()) :: GithubAuthorization.t()
  def get_github_authorization!(id), do: Repo.get!(GithubAuthorization, id)

  @spec create_github_authorization(map()) ::
          {:ok, GithubAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_github_authorization(attrs \\ %{}) do
    %GithubAuthorization{}
    |> GithubAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_github_authorization(GithubAuthorization.t(), map()) ::
          {:ok, GithubAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def update_github_authorization(
        %GithubAuthorization{} = github_authorization,
        attrs
      ) do
    github_authorization
    |> GithubAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec create_or_update_authorization(map()) ::
          {:ok, GithubAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_authorization(%{account_id: account_id} = attrs) do
    case get_authorization_by_account(account_id) do
      %GithubAuthorization{} = authorization ->
        update_github_authorization(authorization, attrs)

      nil ->
        create_github_authorization(attrs)
    end
  end

  @spec delete_github_authorization(GithubAuthorization.t()) ::
          {:ok, GithubAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def delete_github_authorization(%GithubAuthorization{} = github_authorization) do
    Repo.delete(github_authorization)
  end

  @spec change_github_authorization(GithubAuthorization.t(), map()) :: Ecto.Changeset.t()
  def change_github_authorization(
        %GithubAuthorization{} = github_authorization,
        attrs \\ %{}
      ) do
    GithubAuthorization.changeset(github_authorization, attrs)
  end

  @spec get_authorization_by_account(binary(), map()) :: GithubAuthorization.t() | nil
  def get_authorization_by_account(account_id, _filters \\ %{}) do
    GithubAuthorization
    |> where(account_id: ^account_id)
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  @spec find_github_authorization(map()) :: GithubAuthorization.t() | nil
  def find_github_authorization(filters \\ %{}) do
    GithubAuthorization
    |> where(^filter_authorizations_where(filters))
    |> order_by(desc: :inserted_at)
    |> first()
    |> Repo.one()
  end

  defp filter_authorizations_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {:account_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.account_id == ^value)

      {:scope, value}, dynamic ->
        dynamic([r], ^dynamic and r.scope == ^value)

      {:token_type, value}, dynamic ->
        dynamic([r], ^dynamic and r.token_type == ^value)

      {:github_installation_id, value}, dynamic ->
        dynamic([r], ^dynamic and r.github_installation_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
