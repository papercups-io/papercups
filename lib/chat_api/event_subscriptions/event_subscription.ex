defmodule ChatApi.EventSubscriptions.EventSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          scope: String.t() | nil,
          webhook_url: String.t(),
          verified: boolean() | nil,
          # Foreign keys
          account_id: Ecto.UUID.t(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "event_subscriptions" do
    field :scope, :string
    field :webhook_url, :string
    field :verified, :boolean, default: false

    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(event_subscription, attrs) do
    event_subscription
    |> cast(attrs, [:webhook_url, :verified, :account_id, :scope])
    |> validate_required([:webhook_url, :account_id])
  end
end
