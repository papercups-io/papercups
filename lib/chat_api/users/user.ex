defmodule ChatApi.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Mentions.Mention
  alias ChatApi.Accounts.Account
  alias ChatApi.Users.{UserProfile, UserSettings}

  @type t :: %__MODULE__{
          email_confirmation_token: String.t() | nil,
          password_reset_token: String.t() | nil,
          email_confirmed_at: any(),
          disabled_at: any(),
          archived_at: any(),
          role: String.t() | nil,
          has_valid_email: boolean() | nil,
          # Pow fields
          email: String.t(),
          password_hash: String.t(),
          # Relations
          account_id: any(),
          account: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  schema "users" do
    field(:email_confirmation_token, :string)
    field(:password_reset_token, :string)
    field(:email_confirmed_at, :utc_datetime)
    field(:disabled_at, :utc_datetime)
    field(:archived_at, :utc_datetime)
    field(:role, :string, default: "user")
    field(:has_valid_email, :boolean)

    has_many(:conversations, Conversation, foreign_key: :assignee_id)
    has_many(:messages, Message, foreign_key: :user_id)
    belongs_to(:account, Account, type: :binary_id)
    has_one(:profile, UserProfile)
    has_one(:settings, UserSettings)

    has_many(:mentions, Mention)
    has_many(:mentioned_conversations, through: [:mentions, :conversation])
    has_many(:mentioned_messages, through: [:mentions, :message])

    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> cast(attrs, [:account_id, :role])
    |> validate_required([:account_id])
  end

  @spec role_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def role_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:role])
    |> validate_inclusion(:role, ~w(user admin))
  end

  @spec disabled_at_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def disabled_at_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:disabled_at, :archived_at])
    |> validate_required([])
  end

  @spec email_verification_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) ::
          Ecto.Changeset.t()
  def email_verification_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:email_confirmation_token, :email_confirmed_at, :has_valid_email])
    |> validate_required([])
  end

  @spec password_reset_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) ::
          Ecto.Changeset.t()
  def password_reset_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:password_reset_token])
    |> validate_required([])
  end

  @spec password_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) ::
          Ecto.Changeset.t()
  def password_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_password_changeset(attrs)
    |> password_reset_changeset(attrs)
  end
end
