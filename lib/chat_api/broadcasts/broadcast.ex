defmodule ChatApi.Broadcasts.Broadcast do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account
  alias ChatApi.MessageTemplates.MessageTemplate

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          state: String.t() | nil,
          started_at: DateTime.t() | nil,
          finished_at: DateTime.t() | nil,
          # Relations
          account_id: binary(),
          account: any(),
          message_template_id: binary(),
          message_template: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "broadcasts" do
    field(:name, :string)
    field(:description, :string)
    field(:state, :string, default: "unstarted")
    field(:started_at, :utc_datetime)
    field(:finished_at, :utc_datetime)

    belongs_to(:account, Account)
    belongs_to(:message_template, MessageTemplate)

    timestamps()
  end

  @doc false
  def changeset(broadcast, attrs) do
    broadcast
    |> cast(attrs, [
      :name,
      :description,
      :state,
      :started_at,
      :finished_at,
      :account_id,
      :message_template_id
    ])
    |> validate_required([:name, :account_id])
  end
end
