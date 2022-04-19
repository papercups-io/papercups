defmodule ChatApi.Inboxes.InboxMember do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account
  alias ChatApi.Inboxes.Inbox
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          role: String.t(),
          # Relations
          account_id: binary(),
          account: any(),
          inbox_id: binary(),
          inbox: any(),
          user_id: integer(),
          user: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "inbox_members" do
    field(:role, :string, null: false)

    belongs_to(:account, Account)
    belongs_to(:inbox, Inbox)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(inbox, attrs) do
    inbox
    |> cast(attrs, [:role, :account_id, :inbox_id, :user_id])
    |> validate_required([:role, :account_id, :inbox_id, :user_id])
  end
end
