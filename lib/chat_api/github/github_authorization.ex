defmodule ChatApi.Github.GithubAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          access_token: String.t() | nil,
          access_token_expires_at: DateTime.t() | nil,
          refresh_token: String.t() | nil,
          refresh_token_expires_at: DateTime.t() | nil,
          token_type: String.t() | nil,
          scope: String.t() | nil,
          github_installation_id: String.t() | nil,
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
  schema "github_authorizations" do
    field(:access_token, :string)
    field(:access_token_expires_at, :utc_datetime)
    field(:refresh_token, :string)
    field(:refresh_token_expires_at, :utc_datetime)
    field(:token_type, :string)
    field(:scope, :string)
    field(:github_installation_id, :string)
    field(:metadata, :map)

    field(:settings, :map)
    # TODO: update settings to embeds_one:
    # embeds_one(:settings, Settings, on_replace: :delete)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @spec changeset(map(), map()) :: Ecto.Changeset.t()
  def changeset(github_authorization, attrs) do
    github_authorization
    |> cast(attrs, [
      :access_token,
      :access_token_expires_at,
      :refresh_token,
      :refresh_token_expires_at,
      :token_type,
      :scope,
      :github_installation_id,
      :user_id,
      :account_id,
      :metadata,
      :settings
    ])
    |> validate_required([:user_id, :account_id])
  end
end
