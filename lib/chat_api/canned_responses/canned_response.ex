defmodule ChatApi.CannedResponses.CannedResponse do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          name: String.t(),
          content: String.t(),
          # Foreign keys
          account_id: any(),
          account: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "canned_responses" do
    field :content, :string
    field :name, :string

    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(canned_response, attrs) do
    canned_response
    |> cast(attrs, [:name, :content, :account_id])
    |> validate_required([:name, :content, :account_id])
    |> unique_constraint([:name, :account_id])
  end
end
