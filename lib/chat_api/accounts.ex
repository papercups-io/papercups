defmodule ChatApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @spec list_accounts() :: [Account.t()]
  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts()
      [%Account{}, ...]

  """
  def list_accounts do
    Repo.all(Account)
  end

  @spec get_account!(binary()) :: Account.t()
  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id) do
    Account |> Repo.get!(id) |> Repo.preload([[users: :profile], :widget_settings])
  end

  @spec create_account(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    Account.changeset(%Account{}, attrs)
    |> Repo.insert()
  end

  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  @spec update_billing_info(Account.t(), map()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update_billing_info(%Account{} = account, attrs) do
    account
    |> Account.billing_details_changeset(attrs)
    |> Repo.update()
  end

  @spec delete_account(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @spec change_account(Account.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  @spec exists?(binary()) :: boolean()
  def exists?(id) do
    count =
      Account
      |> where(id: ^id)
      |> select([p], count(p.id))
      |> Repo.one()

    count > 0
  end

  @spec get_subscription_plan!(binary()) :: binary()
  def get_subscription_plan!(account_id) do
    Account
    |> where(id: ^account_id)
    |> select([:subscription_plan])
    |> Repo.one!()
    |> Map.get(:subscription_plan)
  end

  @starter_plan_max_users 2

  @spec has_reached_user_capacity?(binary()) :: boolean()
  def has_reached_user_capacity?(account_id) do
    # NB: if you're self-hosting, you can run the following to upgrade your account:
    # ```
    # $ mix set_subscription_plan [YOUR_ACCOUNT_TOKEN] team
    # ```

    # Or, on Heroku:
    # ```
    # $ heroku run "mix set_subscription_plan [YOUR_ACCOUNT_TOKEN] team"
    # ```
    #
    # (These commands would update your account from the "starter" plan to the "team" plan.)
    case get_subscription_plan!(account_id) do
      "starter" -> count_active_users(account_id) >= @starter_plan_max_users
      "team" -> false
      _ -> false
    end
  end

  @spec count_active_users(binary()) :: integer()
  def count_active_users(account_id) do
    User
    |> where(account_id: ^account_id)
    |> where([u], is_nil(u.disabled_at) and is_nil(u.archived_at))
    |> select([p], count(p.id))
    |> Repo.one()
  end
end
