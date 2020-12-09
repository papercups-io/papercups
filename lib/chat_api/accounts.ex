defmodule ChatApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.Repo

  alias ChatApi.Accounts.{Account, WorkingHours}
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

  @spec is_outside_working_hours?(Account.t(), DateTime.t()) :: boolean()
  def is_outside_working_hours?(%Account{working_hours: working_hours}, datetime)
      when is_list(working_hours) do
    minutes_since_midnight = ChatApi.Utils.DateTimeUtils.minutes_since_midnight(datetime)
    day_of_week = ChatApi.Utils.DateTimeUtils.day_of_week(datetime)

    working_hours
    |> Enum.find(fn wh ->
      wh
      |> WorkingHours.day_to_indexes()
      |> Enum.member?(day_of_week)
    end)
    |> case do
      %WorkingHours{start_minute: start_min, end_minute: end_min} ->
        minutes_since_midnight < start_min || minutes_since_midnight > end_min

      _ ->
        true
    end
  end

  def is_outside_working_hours?(_account, _datetime) do
    # For now, just return `false` if no valid working hours are set
    false
  end

  @spec is_outside_working_hours?(Account.t()) :: boolean()
  def is_outside_working_hours?(%Account{time_zone: time_zone} = account)
      when not is_nil(time_zone) do
    case DateTime.now(time_zone) do
      {:ok, datetime} ->
        is_outside_working_hours?(account, datetime)

      {:error, reason} ->
        Logger.error("Invalid time zone #{inspect(time_zone)} - #{inspect(reason)}")

        false
    end
  end

  def is_outside_working_hours?(_account) do
    # For now, if no time zone is found, just assume working hours are not
    # set and return `false`.
    # TODO: how should we handle accounts without a valid time zone?
    false
  end
end
