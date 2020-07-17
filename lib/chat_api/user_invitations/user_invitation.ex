defmodule ChatApi.UserInvitations.UserInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  #number of days the invite is valid
  @days_from_now 3
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  #Id is the invite token
  schema "user_invitations" do
    field(:expires_at, :utc_datetime)
    field(:invite_token, :string)
    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(user_invitation, attrs) do
    user_invitation
    |> cast(attrs, [:account_id, :expires_at])
    # |> generate_token()
    |> set_expires_at()
    |> validate_required([:account_id, :expires_at])
  end

  # defp generate_token(changeset) do
  #   changeset
  #   |> put_change(:invite_token, generate_token())
  # end

  defp generate_token() do
    uuid = Ecto.UUID.generate()
    uuid
  end

  defp set_expires_at(changeset) do
    changeset
    |> put_change(:expires_at, set_expires_at())
  end

  defp set_expires_at() do
    expire_date = DateTime.utc_now() |> DateTime.add(@days_from_now) |> DateTime.truncate(:second)
    expire_date
  end
end
