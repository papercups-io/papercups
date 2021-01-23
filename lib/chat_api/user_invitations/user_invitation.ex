defmodule ChatApi.UserInvitations.UserInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          expires_at: DateTime.t(),
          # Foreign keys
          account_id: Ecto.UUID.t(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Id is the invite token
  schema "user_invitations" do
    field(:expires_at, :utc_datetime)
    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(user_invitation, attrs) do
    user_invitation
    |> cast(attrs, [:account_id, :expires_at])
    |> validate_required([:account_id, :expires_at])
  end
end
