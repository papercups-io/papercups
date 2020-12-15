defmodule ChatApi.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{
    Accounts.Account,
    Customers.Customer,
    Messages.Message,
    Tags.ConversationTag,
    Users.User
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field(:status, :string, default: "open")
    field(:priority, :string, default: "not_priority")
    field(:read, :boolean, default: false)
    field(:archived_at, :utc_datetime)

    has_many(:messages, Message)
    belongs_to(:assignee, User, foreign_key: :assignee_id, references: :id, type: :integer)
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)

    has_many(:conversation_tags, ConversationTag)
    has_many(:tags, through: [:conversation_tags, :tag])

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :status,
      :priority,
      :read,
      :assignee_id,
      :account_id,
      :customer_id,
      :archived_at
    ])
    |> validate_required([:status, :account_id, :customer_id])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:customer_id)
  end

  def test_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:inserted_at, :updated_at, :status])
    |> changeset(attrs)
  end
end
