defmodule ChatApi.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Accounts.Account
  alias ChatApi.Users.{UserProfile, UserSettings}

  schema "users" do
    field(:email_confirmation_token, :string)
    field(:password_reset_token, :string)
    field(:email_confirmed_at, :utc_datetime)
    field(:disabled_at, :utc_datetime)
    field(:archived_at, :utc_datetime)
    field(:role, :string, default: "user")

    has_many(:conversations, Conversation, foreign_key: :assignee_id)
    belongs_to(:account, Account, type: :binary_id)
    has_one(:profile, UserProfile)
    has_one(:settings, UserSettings)

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

  @spec role_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def disabled_at_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:disabled_at, :archived_at])
    |> validate_required([])
  end

  @spec email_verification_changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) ::
          Ecto.Changeset.t()
  def email_verification_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:email_confirmation_token, :email_confirmed_at])
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
