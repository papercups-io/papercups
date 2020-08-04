defmodule ChatApi.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Users.{UserProfile, UserSettings}

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
    UserProfile |> where(user_id: ^user_id) |> Repo.one()
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
