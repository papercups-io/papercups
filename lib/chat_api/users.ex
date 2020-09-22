defmodule ChatApi.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Users.{User, UserProfile, UserSettings}

  def find_user_by_email(email) do
    User |> where(email: ^email) |> Repo.one()
  end

  def find_user_by_email(nil, _account_id), do: nil

  def find_user_by_email(email, account_id) do
    User |> where(account_id: ^account_id, email: ^email) |> Repo.one()
  end

  def find_by_id!(user_id) do
    Repo.get!(User, user_id)
  end

  def find_by_id(user_id, account_id) do
    User |> where(account_id: ^account_id, id: ^user_id) |> Repo.one()
  end

  def find_by_email_confirmation_token(token) do
    User |> where(email_confirmation_token: ^token) |> Repo.one()
  end

  def find_by_password_reset_token(token) do
    User |> where(password_reset_token: ^token) |> Repo.one()
  end

  def send_password_reset_email(user) do
    token = :crypto.strong_rand_bytes(64) |> Base.encode32() |> binary_part(0, 64)

    user
    |> User.password_reset_changeset(%{password_reset_token: token})
    |> Repo.update()
    |> case do
      {:ok, user} -> ChatApi.Emails.send_password_reset_email(user)
      error -> error
    end
  end

  def verify_email(user) do
    user
    |> User.email_verification_changeset(%{
      # email_confirmation_token: nil, # TODO: do we want to do this?
      email_confirmed_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  def update_password(user, params) do
    updates = Map.merge(params, %{"password_reset_token" => nil})

    user
    |> User.password_changeset(updates)
    |> Repo.update()
  end

  @spec create_admin(map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.User}
  def create_admin(params) do
    %User{}
    |> User.changeset(params)
    |> User.role_changeset(%{role: "admin"})
    |> Repo.insert()
  end

  @spec set_admin_role(%User{}) :: {:ok, %User{}} | {:error, Ecto.Changeset.User}
  def set_admin_role(user) do
    user
    |> User.role_changeset(%{role: "admin"})
    |> Repo.update()
  end

  @spec set_user_role(%User{}) :: {:ok, %User{}} | {:error, Ecto.Changeset.User}
  def set_user_role(user) do
    user
    |> User.role_changeset(%{role: "user"})
    |> Repo.update()
  end

  @spec archive_user(%User{}) :: {:ok, %User{}} | {:error, Ecto.Changeset.User}
  def archive_user(user) do
    user
    |> User.disabled_at_changeset(%{archived_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @spec disable_user(%User{}) :: {:ok, %User{}} | {:error, Ecto.Changeset.User}
  def disable_user(user) do
    user
    |> User.disabled_at_changeset(%{disabled_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @spec enable_user(%User{}) :: {:ok, %User{}} | {:error, Ecto.Changeset.User}
  def enable_user(user) do
    user
    |> User.disabled_at_changeset(%{disabled_at: nil})
    |> Repo.update()
  end

  @doc """
  Gets a single user_profile.

  Raises `Ecto.NoResultsError` if the User profile does not exist.

  ## Examples

      iex> get_user_profile(123)
      %UserProfile{}

      iex> get_user_profile(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_profile(user_id) do
    UserProfile |> where(user_id: ^user_id) |> Repo.one() |> Repo.preload(:user)
  end

  def get_user_info(user_id) do
    User
    |> where(id: ^user_id)
    |> Repo.one()
    |> Repo.preload([:profile, :settings])
  end

  @doc """
  Creates a user_profile.

  ## Examples

      iex> create_user_profile(user_id, %{field: value})
      {:ok, %UserProfile{}}

      iex> create_user_profile(user_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_profile(attrs \\ %{}) do
    %UserProfile{}
    |> UserProfile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_profile.

  ## Examples

      iex> update_user_profile(user_profile, %{field: new_value})
      {:ok, %UserProfile{}}

      iex> update_user_profile(user_profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(%UserProfile{} = user_profile, attrs) do
    user_profile
    |> UserProfile.changeset(attrs)
    |> Repo.update()
  end

  def create_or_update_profile(user_id, params) do
    existing = get_user_profile(user_id)

    if existing do
      update_user_profile(existing, params)
    else
      create_user_profile(params)
    end
  end

  @doc """
  Deletes a user_profile.

  ## Examples

      iex> delete_user_profile(user_profile)
      {:ok, %UserProfile{}}

      iex> delete_user_profile(user_profile)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_profile(%UserProfile{} = user_profile) do
    Repo.delete(user_profile)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_profile changes.

  ## Examples

      iex> change_user_profile(user_profile)
      %Ecto.Changeset{data: %UserProfile{}}

  """
  def change_user_profile(%UserProfile{} = user_profile, attrs \\ %{}) do
    UserProfile.changeset(user_profile, attrs)
  end

  def get_user_settings(user_id) do
    UserSettings |> where(user_id: ^user_id) |> Repo.one()
  end

  def create_or_update_settings(user_id, params) do
    existing = get_user_settings(user_id)

    if existing do
      update_user_settings(existing, params)
    else
      create_user_settings(params)
    end
  end

  @doc """
  Creates a user_settings.

  ## Examples

      iex> create_user_settings(%{field: value})
      {:ok, %UserSettings{}}

      iex> create_user_settings(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_settings(attrs \\ %{}) do
    %UserSettings{}
    |> UserSettings.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_settings.

  ## Examples

      iex> update_user_settings(user_settings, %{field: new_value})
      {:ok, %UserSettings{}}

      iex> update_user_settings(user_settings, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_settings(%UserSettings{} = user_settings, attrs) do
    user_settings
    |> UserSettings.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_settings.

  ## Examples

      iex> delete_user_settings(user_settings)
      {:ok, %UserSettings{}}

      iex> delete_user_settings(user_settings)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_settings(%UserSettings{} = user_settings) do
    Repo.delete(user_settings)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_settings changes.

  ## Examples

      iex> change_user_settings(user_settings)
      %Ecto.Changeset{data: %UserSettings{}}

  """
  def change_user_settings(%UserSettings{} = user_settings, attrs \\ %{}) do
    UserSettings.changeset(user_settings, attrs)
  end
end
