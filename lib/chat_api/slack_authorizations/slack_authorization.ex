defmodule ChatApi.SlackAuthorizations.SlackAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.SlackAuthorizations.Settings

  @type t :: %__MODULE__{
          access_token: String.t(),
          type: String.t() | nil,
          app_id: String.t() | nil,
          authed_user_id: String.t() | nil,
          bot_user_id: String.t() | nil,
          channel: String.t() | nil,
          channel_id: String.t() | nil,
          configuration_url: String.t() | nil,
          scope: String.t() | nil,
          team_id: String.t() | nil,
          team_name: String.t() | nil,
          token_type: String.t() | nil,
          webhook_url: String.t() | nil,
          metadata: any(),
          settings: any(),
          # Relations
          account_id: any(),
          account: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slack_authorizations" do
    field(:access_token, :string)
    field(:type, :string, default: "reply")
    field(:app_id, :string)
    field(:authed_user_id, :string)
    field(:bot_user_id, :string)
    field(:channel, :string)
    field(:channel_id, :string)
    field(:configuration_url, :string)
    field(:scope, :string)
    field(:team_id, :string)
    field(:team_name, :string)
    field(:token_type, :string)
    field(:webhook_url, :string)
    field(:metadata, :map)

    embeds_one(:settings, Settings, on_replace: :delete)

    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(slack_authorization, attrs) do
    slack_authorization
    |> cast(attrs, [
      :account_id,
      :type,
      :access_token,
      :app_id,
      :authed_user_id,
      :bot_user_id,
      :channel,
      :channel_id,
      :configuration_url,
      :webhook_url,
      :scope,
      :team_id,
      :team_name,
      :token_type,
      :metadata
    ])
    |> cast_embed(:settings, with: &settings_changeset/2)
    |> validate_required([:account_id, :access_token])
    |> validate_inclusion(:type, ["reply", "support"])
  end

  @spec settings_changeset(any(), map()) :: Ecto.Changeset.t()
  def settings_changeset(schema, params) do
    schema
    |> cast(params, [
      :sync_all_incoming_threads,
      :sync_by_emoji_tagging
    ])
  end
end
