defmodule ChatApi.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Messages.Message
  alias ChatApi.Users.User
  alias ChatApi.Accounts.Account
  alias ChatApi.Customers.Customer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field(:status, :string, default: "open")
    field(:priority, :string, default: "not_priority")
    field(:read, :boolean, default: false)
    has_many(:messages, Message)
    belongs_to(:assignee, User, foreign_key: :assignee_id, references: :id, type: :integer)
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:status, :priority, :read, :assignee_id, :account_id, :customer_id])
    |> validate_required([:status, :account_id])
  end
end
