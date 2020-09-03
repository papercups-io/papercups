defmodule ChatApi.UserInvitations do
  @moduledoc """
  The UserInvitations context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo
  alias ChatApi.UserInvitations.UserInvitation

  @seconds_in_a_day 86_400
  # number of days the invite is valid
  @days_from_now 3

  @doc """
  Returns the list of user_invitations.

  ## Examples

      iex> list_user_invitations(account_id)
      [%UserInvitation{}, ...]

  """
  def list_user_invitations(account_id) do
    UserInvitation |> where(account_id: ^account_id) |> Repo.all()
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
  def get_user_invitation!(id) do
    Repo.get!(UserInvitation, id) |> Repo.preload(:account)
  end

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
    |> set_expires_at()
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

  @doc """
  Sets a user invitation as expired

  ## Examples

      iex> expire_user_invitation(user_invitation)
      {:ok, %UserInvitation{}}

  """
  def expire_user_invitation(%UserInvitation{} = user_invitation) do
    user_invitation
    |> update_user_invitation(%{expires_at: DateTime.utc_now() |> DateTime.truncate(:second)})
  end

  @doc """
  Checks if the user invitation has expired

  ## Examples

      iex> expired?(user_invitation)
      true

      iex> expired?(user_invitation)
      false
  """
  def expired?(%UserInvitation{} = user_invitation) do
    DateTime.utc_now() |> DateTime.truncate(:second) >= user_invitation.expires_at
  end

  defp set_expires_at(invitation) do
    %{
      invitation
      | expires_at:
          DateTime.utc_now()
          |> DateTime.add(@seconds_in_a_day * @days_from_now, :second)
          |> DateTime.truncate(:second)
    }
  end
end
