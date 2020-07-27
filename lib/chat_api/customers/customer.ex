defmodule ChatApi.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customers" do
    field(:first_seen, :date)
    field(:last_seen, :date)
    has_many(:messages, Message)
    has_many(:conversations, Conversation)
    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:first_seen, :last_seen, :account_id])
    |> validate_required([:first_seen, :last_seen, :account_id])
  end
end
