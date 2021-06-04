defmodule ChatApi.Mattermost.MattermostAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          access_token: String.t(),
          refresh_token: String.t() | nil,
          bot_token: String.t() | nil,
          verification_token: String.t() | nil,
          mattermost_url: String.t() | nil,
          channel_id: String.t() | nil,
          channel_name: String.t() | nil,
          team_id: String.t() | nil,
          team_domain: String.t() | nil,
          webhook_url: String.t() | nil,
          scope: String.t() | nil,
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
  schema "mattermost_authorizations" do
    field(:access_token, :string, null: false)
    field(:refresh_token, :string)
    field(:bot_token, :string)
    field(:verification_token, :string)
    field(:mattermost_url, :string)
    field(:channel_id, :string)
    field(:channel_name, :string)
    field(:team_id, :string)
    field(:team_domain, :string)
    field(:webhook_url, :string)
    field(:scope, :string)
    field(:metadata, :map)

    field(:settings, :map)
    # TODO: update settings to embeds_one:
    # embeds_one(:settings, Settings, on_replace: :delete)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(mattermost_authorization, attrs) do
    mattermost_authorization
    |> cast(attrs, [
      :access_token,
      :refresh_token,
      :bot_token,
      :verification_token,
      :mattermost_url,
      :channel_id,
      :channel_name,
      :team_id,
      :team_domain,
      :webhook_url,
      :scope,
      :metadata,
      :settings,
      :user_id,
      :account_id
    ])
    |> validate_required([:access_token, :user_id, :account_id])
  end
end
