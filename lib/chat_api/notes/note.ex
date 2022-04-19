defmodule ChatApi.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Customers.Customer
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          body: String.t(),
          content_type: String.t(),
          # Relations
          account_id: any(),
          account: any(),
          customer_id: any(),
          customer: any(),
          author_id: any(),
          author: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field(:body, :string)
    field(:content_type, :string, default: "text")

    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:author, User, foreign_key: :author_id, references: :id, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:body, :content_type, :author_id, :account_id, :customer_id])
    # partial updates are allowed if required value is already populated: https://hexdocs.pm/ecto/Ecto.Changeset.html#validate_required/3
    |> validate_required([:body, :author_id, :account_id, :customer_id])
  end
end
