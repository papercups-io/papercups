defmodule ChatApi.ForwardingAddresses.ForwardingAddress do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account
  alias ChatApi.Inboxes.Inbox

  @type t :: %__MODULE__{
          forwarding_email_address: String.t(),
          source_email_address: String.t() | nil,
          state: String.t() | nil,
          description: String.t() | nil,
          # Relations
          account_id: binary(),
          account: any(),
          inbox_id: binary(),
          inbox: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "forwarding_addresses" do
    field(:forwarding_email_address, :string)
    field(:source_email_address, :string)
    field(:state, :string)
    field(:description, :string)

    belongs_to(:account, Account)
    belongs_to(:inbox, Inbox)

    timestamps()
  end

  @doc false
  def changeset(forwarding_address, attrs) do
    forwarding_address
    |> cast(attrs, [
      :forwarding_email_address,
      :source_email_address,
      :state,
      :description,
      :account_id,
      :inbox_id
    ])
    |> validate_required([
      :forwarding_email_address,
      :account_id
    ])
    |> unique_constraint(:forwarding_email_address)
  end
end
