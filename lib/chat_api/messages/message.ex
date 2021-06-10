defmodule ChatApi.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Accounts.Account
  alias ChatApi.Customers.Customer
  alias ChatApi.Users.User
  alias ChatApi.Messages.MessageFile

  @type t :: %__MODULE__{
          body: String.t(),
          subject: String.t() | nil,
          sent_at: DateTime.t() | nil,
          seen_at: DateTime.t() | nil,
          source: String.t(),
          type: String.t(),
          private: boolean() | nil,
          metadata: map() | nil,
          # Foreign keys
          conversation_id: Ecto.UUID.t(),
          conversation: any(),
          account_id: Ecto.UUID.t(),
          account: any(),
          customer_id: Ecto.UUID.t(),
          customer: any(),
          user_id: integer(),
          user: any(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:body, :string)
    field(:sent_at, :utc_datetime)
    field(:seen_at, :utc_datetime)
    field(:source, :string, default: "chat")
    field(:type, :string, default: "reply")
    field(:subject, :string)
    field(:private, :boolean, default: false)
    field(:metadata, :map)

    belongs_to(:conversation, Conversation)
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:user, User, type: :integer)

    has_many(:message_files, MessageFile)
    has_many(:attachments, through: [:message_files, :file])

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :body,
      :type,
      :private,
      :conversation_id,
      :account_id,
      :customer_id,
      :user_id,
      :sent_at,
      :seen_at,
      :source,
      :subject,
      :metadata
    ])
    |> validate_required([:account_id, :conversation_id])
    |> validate_inclusion(:type, ["reply", "note", "bot"])
    |> validate_inclusion(:source, [
      "chat",
      "slack",
      "mattermost",
      "email",
      "sms",
      "api",
      "sandbox"
    ])
  end
end
