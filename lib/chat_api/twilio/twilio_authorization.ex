defmodule ChatApi.Twilio.TwilioAuthorization do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          twilio_auth_token: String.t(),
          twilio_account_sid: String.t(),
          from_phone_number: String.t(),
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
  schema "twilio_authorizations" do
    field(:twilio_auth_token, :string, null: false)
    field(:twilio_account_sid, :string, null: false)
    field(:from_phone_number, :string, null: false)
    field(:metadata, :map)

    field(:settings, :map)
    # TODO: update settings to embeds_one:
    # embeds_one(:settings, Settings, on_replace: :delete)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(twilio_authorization, attrs) do
    twilio_authorization
    |> cast(attrs, [
      :twilio_auth_token,
      :twilio_account_sid,
      :from_phone_number,
      :metadata,
      :settings,
      :user_id,
      :account_id
    ])
    |> validate_required([
      :twilio_auth_token,
      :twilio_account_sid,
      :from_phone_number,
      :user_id,
      :account_id
    ])
  end
end
