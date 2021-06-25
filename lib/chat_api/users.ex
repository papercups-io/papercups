defmodule ChatApi.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Users.{User, UserProfile, UserSettings}

  @spec find_user_by_email(binary()) :: User.t() | nil
  def find_user_by_email(email) do
    User |> where(email: ^email) |> Repo.one()
  end

  @spec find_user_by_email(binary() | nil, binary()) :: User.t() | nil
  def find_user_by_email(nil, _account_id), do: nil

  def find_user_by_email(email, account_id) do
    User |> where(account_id: ^account_id, email: ^email) |> Repo.one()
  end

  @spec list_users_by_account(binary()) :: [User.t()]
  def list_users_by_account(account_id, filters \\ %{}) do
    User
    |> where(account_id: ^account_id)
    |> where([u], is_nil(u.disabled_at))
    |> where(^filter_where(filters))
    |> Repo.all()
    |> Repo.preload([:profile, :settings])
  end

  @spec find_by_id!(integer() | binary()) :: User.t()
  def find_by_id!(user_id) do
    Repo.get!(User, user_id)
  end

  @spec find_by_id(integer() | binary(), binary()) :: User.t() | nil
  def find_by_id(user_id, account_id) do
    User |> where(account_id: ^account_id, id: ^user_id) |> Repo.one()
  end

  @spec find_by_email_confirmation_token(binary()) :: User.t() | nil
  def find_by_email_confirmation_token(token) do
    User |> where(email_confirmation_token: ^token) |> Repo.one()
  end

  @spec find_by_password_reset_token(binary()) :: User.t() | nil
  def find_by_password_reset_token(token) do
    User |> where(password_reset_token: ^token) |> Repo.one()
  end

  @spec find_by_api_key(binary()) :: User.t() | nil
  def find_by_api_key(api_key) do
    case ChatApi.ApiKeys.find_personal_api_key_by_value(api_key) do
      %{user: %User{} = user} -> user
      _ -> nil
    end
  end

  @spec send_password_reset_email(User.t()) ::
          ChatApi.Emails.deliver_result() | {:error, Ecto.Changeset.t()}
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

  @spec verify_email(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def verify_email(user) do
    user
    |> User.email_verification_changeset(%{
      # email_confirmation_token: nil, # TODO: do we want to do this?
      email_confirmed_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  @spec validate_email(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def validate_email(user) do
    user
    |> User.email_verification_changeset(%{
      has_valid_email: has_valid_email?(user)
    })
    |> Repo.update()
  end

  @spec set_has_valid_email(User.t(), boolean()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def set_has_valid_email(user, has_valid_email) do
    user
    |> User.email_verification_changeset(%{
      has_valid_email: has_valid_email
    })
    |> Repo.update()
  end

  @spec has_valid_email?(User.t()) :: boolean() | nil
  def has_valid_email?(%User{email: email}) do
    if ChatApi.Emails.Debounce.enabled?() do
      !ChatApi.Emails.Debounce.disposable?(email) &&
        ChatApi.Emails.Debounce.valid?(email)
    else
      # Use nil to indicate that the validation hasn't occurred yet
      nil
    end
  end

  @spec update_password(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_password(user, params) do
    updates = Map.merge(params, %{"password_reset_token" => nil})

    user
    |> User.password_changeset(updates)
    |> Repo.update()
  end

  @spec create_admin(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_admin(params) do
    Map.merge(params, %{role: "admin"})
    |> create_user()
  end

  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(user) do
    user
    |> Repo.delete()
  end

  @spec set_admin_role(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def set_admin_role(user) do
    user
    |> User.role_changeset(%{role: "admin"})
    |> Repo.update()
  end

  @spec set_user_role(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def set_user_role(user) do
    user
    |> User.role_changeset(%{role: "user"})
    |> Repo.update()
  end

  @spec archive_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def archive_user(user) do
    user
    |> User.disabled_at_changeset(%{archived_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @spec disable_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def disable_user(user) do
    user
    |> User.disabled_at_changeset(%{disabled_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @spec enable_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def enable_user(user) do
    user
    |> User.disabled_at_changeset(%{disabled_at: nil})
    |> Repo.update()
  end

  @spec get_user_profile(integer()) :: UserProfile.t() | nil
  @doc """
  Gets a single user_profile.

  creates new UserProfile if the User profile does not exist.

  ## Examples

      iex> get_user_profile(123)
      %UserProfile{}

  """
  def get_user_profile(user_id) do
    UserProfile
    |> where(user_id: ^user_id)
    |> Repo.one()
    |> case do
      %UserProfile{} = profile ->
        profile
        |> Repo.preload(:user)

      nil ->
        create_user_profile(user_id)
    end
  end

  defp create_user_profile(user_id) do
    %UserProfile{}
    |> UserProfile.changeset(%{user_id: user_id})
    |> Repo.insert()
    |> case do
      {:ok, profile} ->
        profile
        |> Repo.preload(:user)

      {:error, _reason} ->
        nil
    end
  end

  @spec get_user_info(integer()) :: User.t() | nil
  def get_user_info(user_id) do
    User
    |> where(id: ^user_id)
    |> Repo.one()
    |> Repo.preload([:profile, :settings])
  end

  @spec get_user_info(binary(), integer()) :: User.t() | nil
  def get_user_info(account_id, user_id) do
    User
    |> where(id: ^user_id, account_id: ^account_id)
    |> Repo.one()
    |> Repo.preload([:profile, :settings])
  end

  @spec update_user_profile(integer(), map()) ::
          {:ok, UserProfile.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a user_profile.

  ## Examples

      iex> update_user_profile(user_id, %{field: new_value})
      {:ok, %UserProfile{}}

      iex> update_user_profile(user_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(user_id, attrs) do
    get_user_profile(user_id)
    |> UserProfile.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_user_profile(UserProfile.t()) ::
          {:ok, UserProfile.t()} | {:error, Ecto.Changeset.t()}
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

  @spec change_user_profile(UserProfile.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_profile changes.

  ## Examples

      iex> change_user_profile(user_profile)
      %Ecto.Changeset{data: %UserProfile{}}

  """
  def change_user_profile(%UserProfile{} = user_profile, attrs \\ %{}) do
    UserProfile.changeset(user_profile, attrs)
  end

  @spec get_user_settings(integer()) :: UserSettings.t() | nil
  @doc """
  Gets a single user_settings.

  creates new UserSettings if the User settings does not exist.

  ## Examples

      iex> get_user_settings(123)
      %UserSettings{}

  """
  def get_user_settings(user_id) do
    UserSettings
    |> where(user_id: ^user_id)
    |> Repo.one()
    |> case do
      %UserSettings{} = setting ->
        setting

      nil ->
        create_user_setting(user_id)
    end
  end

  defp create_user_setting(user_id) do
    %UserSettings{}
    |> UserSettings.changeset(%{user_id: user_id})
    |> Repo.insert()
    |> case do
      {:ok, setting} -> setting
      {:serror, _reason} -> nil
    end
  end

  @spec update_user_settings(integer(), map()) ::
          {:ok, UserSettings.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates a user_settings.

  ## Examples

      iex> update_user_settings(user_id, %{field: new_value})
      {:ok, %UserSettings{}}

      iex> update_user_settings(user_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_settings(user_id, params) do
    get_user_settings(user_id)
    |> UserSettings.changeset(params)
    |> Repo.update()
  end

  @spec delete_user_settings(UserSettings.t()) ::
          {:ok, UserSettings.t()} | {:error, Ecto.Changeset.t()}
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

  @spec change_user_settings(UserSettings.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_settings changes.

  ## Examples

      iex> change_user_settings(user_settings)
      %Ecto.Changeset{data: %UserSettings{}}

  """
  def change_user_settings(%UserSettings{} = user_settings, attrs \\ %{}) do
    UserSettings.changeset(user_settings, attrs)
  end

  @spec filter_where(map) :: %Ecto.Query.DynamicExpr{}
  def filter_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"email", value}, dynamic ->
        dynamic([u], ^dynamic and u.email == ^value)

      {"role", value}, dynamic ->
        dynamic([u], ^dynamic and u.role == ^value)

      {"has_valid_email", value}, dynamic ->
        dynamic([u], ^dynamic and u.has_valid_email == ^value)

      {"active", "true"}, dynamic ->
        dynamic([u], ^dynamic and is_nil(u.disabled_at) and is_nil(u.archived_at))

      {"active", "false"}, dynamic ->
        dynamic([u], ^dynamic and (not is_nil(u.disabled_at) or not is_nil(u.archived_at)))

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end
end
