defmodule ChatApi.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Accounts.Account
  alias ChatApi.Customers.Customer
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          body: String.t(),
          sent_at: any(),
          seen_at: any(),
          source: String.t() | nil,
          metadata: any(),
          # Foreign keys
          conversation_id: any(),
          conversation: any(),
          account_id: any(),
          account: any(),
          customer_id: any(),
          customer: any(),
          user_id: any(),
          user: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:body, :string)
    field(:sent_at, :utc_datetime)
    field(:seen_at, :utc_datetime)
    field(:source, :string, default: "chat")
    field(:metadata, :map)

    belongs_to(:conversation, Conversation)
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :body,
      :conversation_id,
      :account_id,
      :customer_id,
      :user_id,
      :sent_at,
      :seen_at,
      :source,
      :metadata
    ])
    |> validate_required([:body, :account_id, :conversation_id])
    |> validate_inclusion(:source, ["chat", "slack", "email"])
  end
end
