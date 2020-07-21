defmodule ChatApi.SlackAuthorizations.SlackAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slack_authorizations" do
    field :access_token, :string
    field :app_id, :string
    field :authed_user_id, :string
    field :bot_user_id, :string
    field :channel, :string
    field :channel_id, :string
    field :configuration_url, :string
    field :scope, :string
    field :team_id, :string
    field :team_name, :string
    field :token_type, :string
    field :webhook_url, :string

    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(slack_authorization, attrs) do
    slack_authorization
    |> cast(attrs, [
      :account_id,
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
      :token_type
    ])
    |> validate_required([:account_id, :access_token])
  end
end
