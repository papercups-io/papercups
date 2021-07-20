defmodule ChatApi.Mentions.Mention do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          seen_at: DateTime.t() | nil,
          # Relations
          account_id: binary(),
          account: any(),
          conversation_id: binary(),
          conversation: any(),
          message_id: binary(),
          message: any(),
          user_id: any(),
          user: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "mentions" do
    field(:seen_at, :utc_datetime)

    belongs_to(:account, Account)
    belongs_to(:conversation, Conversation)
    belongs_to(:message, Message)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(mention, attrs) do
    mention
    |> cast(attrs, [:seen_at])
    |> validate_required([:seen_at])
  end
end
