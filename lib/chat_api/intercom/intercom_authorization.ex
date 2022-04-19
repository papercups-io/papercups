defmodule ChatApi.Intercom.IntercomAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          token_type: String.t() | nil,
          scope: String.t() | nil,
          metadata: any(),
          # Foreign keys
          account_id: Ecto.UUID.t(),
          user_id: integer(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "intercom_authorizations" do
    field(:access_token, :string, null: false)
    field(:token_type, :string)
    field(:scope, :string)
    field(:metadata, :map)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(intercom_authorization, attrs) do
    intercom_authorization
    |> cast(attrs, [
      :account_id,
      :user_id,
      :access_token,
      :token_type,
      :scope,
      :metadata
    ])
    |> validate_required([
      :account_id,
      :access_token
    ])
  end
end
