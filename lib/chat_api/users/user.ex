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
    |> cast(attrs, [:account_id])
    |> validate_required([:account_id])
  end

  def email_verification_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:email_confirmation_token, :email_confirmed_at])
    |> validate_required([])
  end

  def password_reset_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:password_reset_token])
    |> validate_required([])
  end

  def password_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_password_changeset(attrs)
    |> password_reset_changeset(attrs)
  end
end
