defmodule ChatApi.Tags.CustomerTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{Accounts.Account, Customers.Customer, Tags.Tag, Users.User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customer_tags" do
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:tag, Tag)
    belongs_to(:creator, User, foreign_key: :creator_id, references: :id, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:account_id, :customer_id, :tag_id, :creator_id])
    |> validate_required([:account_id, :customer_id, :tag_id])
  end
end
