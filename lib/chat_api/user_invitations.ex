defmodule ChatApi.UserInvitations do
  @moduledoc """
  The UserInvitations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.UserInvitations.UserInvitation

  @doc """
  Returns the list of user_invitations.

  ## Examples

      iex> list_user_invitations()
      [%UserInvitation{}, ...]

  """
  def list_user_invitations do
    Repo.all(UserInvitation)
  end

  @doc """
  Gets a single user_invitation.

  Raises `Ecto.NoResultsError` if the User invitation does not exist.

  ## Examples

      iex> get_user_invitation!(123)
      %UserInvitation{}

      iex> get_user_invitation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_invitation!(id), do: Repo.get!(UserInvitation, id)

  @doc """
  Creates a user_invitation.

  ## Examples

      iex> create_user_invitation(%{field: value})
      {:ok, %UserInvitation{}}

      iex> create_user_invitation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_invitation(attrs \\ %{}) do
    %UserInvitation{}
    |> UserInvitation.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_user_invitation(
          ChatApi.UserInvitations.UserInvitation.t(),
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
  @doc """
  Updates a user_invitation.

  ## Examples

      iex> update_user_invitation(user_invitation, %{field: new_value})
      {:ok, %UserInvitation{}}

      iex> update_user_invitation(user_invitation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_invitation(%UserInvitation{} = user_invitation, attrs) do
    user_invitation
    |> UserInvitation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_invitation.

  ## Examples

      iex> delete_user_invitation(user_invitation)
      {:ok, %UserInvitation{}}

      iex> delete_user_invitation(user_invitation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_invitation(%UserInvitation{} = user_invitation) do
    Repo.delete(user_invitation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_invitation changes.

  ## Examples

      iex> change_user_invitation(user_invitation)
      %Ecto.Changeset{data: %UserInvitation{}}

  """
  def change_user_invitation(%UserInvitation{} = user_invitation, attrs \\ %{}) do
    UserInvitation.changeset(user_invitation, attrs)
  end
end
