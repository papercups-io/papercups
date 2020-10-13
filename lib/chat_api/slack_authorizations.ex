defmodule ChatApi.SlackAuthorizations do
  @moduledoc """
  The SlackAuthorizations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @spec list_slack_authorizations() :: [SlackAuthorization.t()]
  @doc """
  Returns the list of slack_authorizations.

  ## Examples

      iex> list_slack_authorizations()
      [%SlackAuthorization{}, ...]

  """
  def list_slack_authorizations do
    Repo.all(SlackAuthorization)
  end

  @spec get_slack_authorization!(binary()) :: SlackAuthorization.t()
  @doc """
  Gets a single slack_authorization.

  Raises `Ecto.NoResultsError` if the Slack authorization does not exist.

  ## Examples

      iex> get_slack_authorization!(123)
      %SlackAuthorization{}

      iex> get_slack_authorization!(456)
      ** (Ecto.NoResultsError)

  """
  def get_slack_authorization!(id), do: Repo.get!(SlackAuthorization, id)

  @spec get_authorization_by_account(binary()) :: SlackAuthorization.t() | nil
  def get_authorization_by_account(account_id) do
    SlackAuthorization
    |> where(account_id: ^account_id)
    |> order_by(desc: :inserted_at)
    |> Repo.one()
  end

  @spec create_or_update(binary(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update(account_id, params) do
    existing = get_authorization_by_account(account_id)

    if existing do
      update_slack_authorization(existing, params)
    else
      create_slack_authorization(params)
    end
  end

  @spec create_slack_authorization(map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a slack_authorization.

  ## Examples

      iex> create_slack_authorization(%{field: value})
      {:ok, %SlackAuthorization{}}

      iex> create_slack_authorization(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_slack_authorization(attrs \\ %{}) do
    %SlackAuthorization{}
    |> SlackAuthorization.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_slack_authorization(SlackAuthorization.t(), map()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a slack_authorization.

  ## Examples

      iex> update_slack_authorization(slack_authorization, %{field: new_value})
      {:ok, %SlackAuthorization{}}

      iex> update_slack_authorization(slack_authorization, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_slack_authorization(%SlackAuthorization{} = slack_authorization, attrs) do
    slack_authorization
    |> SlackAuthorization.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_slack_authorization(SlackAuthorization.t()) ::
          {:ok, SlackAuthorization.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a slack_authorization.

  ## Examples

      iex> delete_slack_authorization(slack_authorization)
      {:ok, %SlackAuthorization{}}

      iex> delete_slack_authorization(slack_authorization)
      {:error, %Ecto.Changeset{}}

  """
  def delete_slack_authorization(%SlackAuthorization{} = slack_authorization) do
    Repo.delete(slack_authorization)
  end

  @spec change_slack_authorization(SlackAuthorization.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking slack_authorization changes.

  ## Examples

      iex> change_slack_authorization(slack_authorization)
      %Ecto.Changeset{data: %SlackAuthorization{}}

  """
  def change_slack_authorization(%SlackAuthorization{} = slack_authorization, attrs \\ %{}) do
    SlackAuthorization.changeset(slack_authorization, attrs)
  end
end
