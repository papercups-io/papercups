defmodule ChatApi.UserProfiles do
  @moduledoc """
  The UserProfiles context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.UserProfiles.UserProfile

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
end
