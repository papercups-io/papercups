defmodule ChatApi.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field :body, :string
    field :author_id, :integer
    field :account_id, :binary_id
    field :customer_id, :binary_id

    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:author, User, foreign_key: :author_id, references: :id, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:body, :author_id, :customer_id])
    |> validate_required([:body, :author_id, :customer_id])
  end
end
