defmodule ChatApi.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Accounts.Account
  alias ChatApi.UserProfiles.UserProfile

  schema "users" do
    field(:email_alert_on_new_message, :boolean)
    has_many(:conversations, Conversation, foreign_key: :assignee_id)
    belongs_to(:account, Account, type: :binary_id)
    has_one(:profile, UserProfile)

    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> cast(attrs, [:account_id, :email_alert_on_new_message])
    |> validate_required([:account_id])
  end
end
