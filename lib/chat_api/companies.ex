defmodule ChatApi.Companies do
  @moduledoc """
  The Companies context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Companies.Company

  @spec list_companies(binary()) :: [Company.t()]
  def list_companies(account_id) do
    Company |> where(account_id: ^account_id) |> Repo.all()
  end

  @spec get_company!(binary()) :: Company.t()
  def get_company!(id), do: Repo.get!(Company, id)

  @spec create_company(map()) :: {:ok, Company.t()} | {:error, Ecto.Changeset.t()}
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_company(Company.t(), map()) :: {:ok, Company.t()} | {:error, Ecto.Changeset.t()}
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_company(Company.t()) :: {:ok, Company.t()} | {:error, Ecto.Changeset.t()}
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  @spec change_company(Company.t(), map()) :: Ecto.Changeset.t()
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end
end
