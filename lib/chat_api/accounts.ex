defmodule ChatApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.Repo

  alias ChatApi.Accounts.{Account, Settings, WorkingHours}
  alias ChatApi.Users.User

  @spec list_accounts() :: [Account.t()]
  def list_accounts do
    Repo.all(Account)
  end

  @spec get_account!(binary()) :: Account.t()
  def get_account!(id) do
    Account
    |> join(:left, [a], u in assoc(a, :users), as: :users)
    |> join(:left, [a, users: u], p in assoc(u, :profile), as: :profile)
    |> where([_a, users: u], is_nil(u.archived_at))
    |> preload([_a, users: u, profile: p], [:widget_settings, users: {u, profile: p}])
    |> Repo.get!(id)
  end

  @spec create_account(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(attrs \\ %{}) do
    Account.changeset(%Account{}, attrs)
    |> Repo.insert()
  end

  @spec update_account(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
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
  def delete_account(%Account{} = account) do
    Repo.delete(account)
  end

  @spec change_account(Account.t(), map()) :: Ecto.Changeset.t()
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

  @spec get_account_settings!(binary()) :: Settings.t()
  def get_account_settings!(account_id) do
    Account
    |> where(id: ^account_id)
    |> select([:settings])
    |> Repo.one!()
    |> Map.get(:settings, %{})
  end

  @starter_plan_max_users 2
  @lite_plan_max_users 4

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
      "lite" -> count_active_users(account_id) >= @lite_plan_max_users
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

  @spec get_primary_user(binary()) :: User.t()
  def get_primary_user(account_id) do
    User
    |> where(account_id: ^account_id, role: "admin")
    |> where([u], is_nil(u.disabled_at) and is_nil(u.archived_at))
    |> order_by(asc: :inserted_at)
    |> first()
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
