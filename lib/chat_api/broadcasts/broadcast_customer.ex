defmodule ChatApi.Broadcasts.BroadcastCustomer do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account
  alias ChatApi.Broadcasts.Broadcast
  alias ChatApi.Customers.Customer

  @type t :: %__MODULE__{
          state: String.t(),
          sent_at: DateTime.t() | nil,
          # Relations
          account_id: binary(),
          account: any(),
          broadcast_id: binary(),
          broadcast: any(),
          customer_id: binary(),
          customer: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "broadcast_customers" do
    field(:state, :string, default: "unsent")
    field(:sent_at, :utc_datetime)

    belongs_to(:account, Account)
    belongs_to(:broadcast, Broadcast)
    belongs_to(:customer, Customer)

    timestamps()
  end

  @doc false
  def changeset(broadcast, attrs) do
    broadcast
    |> cast(attrs, [
      :state,
      :sent_at,
      :account_id,
      :broadcast_id,
      :customer_id
    ])
    |> validate_required([:state, :account_id, :broadcast_id, :customer_id])
  end
end
