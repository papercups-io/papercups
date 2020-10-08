defmodule ChatApi.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Tags.{ConversationTag, CustomerTag}
  alias ChatApi.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field(:name, :string, null: false)
    field(:description, :string)
    field(:color, :string)

    belongs_to(:account, Account)
    belongs_to(:creator, User, foreign_key: :creator_id, references: :id, type: :integer)

    has_many(:conversation_tags, ConversationTag)
    has_many(:conversations, through: [:conversation_tags, :conversation])
    has_many(:customer_tags, CustomerTag)
    has_many(:customers, through: [:customer_tags, :customer])

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :account_id, :description, :color, :creator_id])
    |> validate_required([:name, :account_id])
    |> unique_constraint(:name)
  end
end
