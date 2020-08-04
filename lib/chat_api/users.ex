defmodule ChatApi.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.Users.UserSettings

  @doc """
  Returns the list of user_settings.

  ## Examples

      iex> list_user_settings()
      [%UserSettings{}, ...]

  """
  def list_user_settings do
    Repo.all(UserSettings)
  end

  @doc """
  Gets a single user_settings.

  Raises `Ecto.NoResultsError` if the User settings does not exist.

  ## Examples

      iex> get_user_settings!(123)
      %UserSettings{}

      iex> get_user_settings!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_settings!(id), do: Repo.get!(UserSettings, id)

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
