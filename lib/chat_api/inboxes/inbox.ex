defmodule ChatApi.Inboxes.Inbox do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          slug: String.t() | nil,
          is_primary: boolean(),
          is_private: boolean(),
          # Relations
          account_id: binary(),
          account: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "inboxes" do
    field(:name, :string, null: false)
    field(:description, :string)
    field(:slug, :string)
    field(:is_primary, :boolean, default: false)
    field(:is_private, :boolean, default: false)

    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(inbox, attrs) do
    inbox
    |> cast(attrs, [:name, :description, :is_primary, :is_private, :account_id])
    |> validate_required([:name, :account_id])
  end
end
