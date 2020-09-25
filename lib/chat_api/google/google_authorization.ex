defmodule ChatApi.Google.GoogleAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "google_authorizations" do
    field(:client, :string)
    field(:access_token, :string)
    field(:refresh_token, :string, null: false)
    field(:token_type, :string)
    field(:expires_at, :integer)
    field(:scope, :string)

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
      :user_id,
      :account_id
    ])
    |> validate_required([:client, :refresh_token, :user_id, :account_id])
  end
end
