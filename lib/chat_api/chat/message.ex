defmodule ChatApi.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Accounts.Account
  alias ChatApi.Customers.Customer
  alias ChatApi.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:body, :string)
    field(:sent_at, :utc_datetime)
    field(:seen_at, :utc_datetime)

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
      :seen_at
    ])
    |> validate_required([:body, :account_id, :conversation_id])
  end
end
