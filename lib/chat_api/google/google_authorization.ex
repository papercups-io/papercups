defmodule ChatApi.Google.GoogleAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          client: String.t(),
          access_token: String.t() | nil,
          refresh_token: String.t(),
          token_type: String.t() | nil,
          expires_at: integer(),
          scope: String.t() | nil,
          type: String.t() | nil,
          metadata: any(),
          settings: any(),
          # Foreign keys
          account_id: Ecto.UUID.t(),
          user_id: integer(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "google_authorizations" do
    field(:client, :string)
    field(:access_token, :string)
    field(:refresh_token, :string, null: false)
    field(:token_type, :string)
    field(:expires_at, :integer)
    field(:scope, :string)
    field(:type, :string)
    field(:metadata, :map)

    field(:settings, :map)
    # TODO: update settings to embeds_one:
    # embeds_one(:settings, Settings, on_replace: :delete)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(google_authorization, attrs) do
    google_authorization
    |> cast(attrs, [
      :client,
      :access_token,
      :refresh_token,
      :token_type,
      :expires_at,
      :scope,
      :type,
      :metadata,
      :settings,
      :user_id,
      :account_id
    ])
    |> validate_required([:client, :refresh_token, :user_id, :account_id])
    |> validate_inclusion(:type, ["personal", "support", "sheets"])
  end
end
