defmodule ChatApi.Hubspot.HubspotAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          expires_at: DateTime.t() | nil,
          token_type: String.t() | nil,
          hubspot_app_id: integer() | nil,
          hubspot_portal_id: integer() | nil,
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
  schema "hubspot_authorizations" do
    field(:access_token, :string)
    field(:refresh_token, :string)
    field(:expires_at, :utc_datetime)
    field(:token_type, :string)
    field(:hubspot_app_id, :integer)
    field(:hubspot_portal_id, :integer)
    field(:scope, :string)
    field(:metadata, :map)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(hubspot_authorization, attrs) do
    hubspot_authorization
    |> cast(attrs, [
      :account_id,
      :user_id,
      :access_token,
      :refresh_token,
      :expires_at,
      :token_type,
      :hubspot_app_id,
      :hubspot_portal_id,
      :scope,
      :metadata
    ])
    |> validate_required([
      :account_id,
      :access_token,
      :refresh_token
    ])
  end
end
