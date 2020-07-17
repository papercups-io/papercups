defmodule ChatApi.UserInvitations.UserInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_invitations" do
    field(:expires_at, :date)
    field(:token, :string)
    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(user_invitation, attrs) do
    user_invitation
    |> cast(attrs, [:token, :account_id, :expires_at])
    |> validate_required([:token, :account_id, :expires_at])
  end
end
