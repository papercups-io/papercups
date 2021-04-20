defmodule ChatApi.Issues.CustomerIssue do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{Accounts.Account, Customers.Customer, Issues.Issue, Users.User}

  @type t :: %__MODULE__{
          # Foreign keys
          account_id: Ecto.UUID.t(),
          customer_id: Ecto.UUID.t(),
          issue_id: Ecto.UUID.t(),
          creator_id: integer() | nil,
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customer_issues" do
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:issue, Issue)
    belongs_to(:creator, User, foreign_key: :creator_id, references: :id, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:account_id, :customer_id, :issue_id, :creator_id])
    |> validate_required([:account_id, :customer_id, :issue_id])
  end
end
