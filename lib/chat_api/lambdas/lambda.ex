defmodule ChatApi.Lambdas.Lambda do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          code: String.t(),
          description: String.t(),
          language: String.t(),
          last_deployed_at: DateTime.t() | nil,
          last_executed_at: DateTime.t() | nil,
          name: String.t(),
          runtime: String.t(),
          status: String.t(),
          lambda_function_name: String.t() | nil,
          lambda_function_handler: String.t() | nil,
          lambda_revision_id: String.t() | nil,
          lambda_last_update_status: String.t() | nil,
          metadata: map() | nil,
          # Relations
          account_id: any(),
          account: any(),
          creator_id: any(),
          creator: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lambdas" do
    field(:code, :string)
    field(:description, :string)
    field(:language, :string)
    field(:last_deployed_at, :utc_datetime)
    field(:last_executed_at, :utc_datetime)
    field(:metadata, :map)
    field(:name, :string)
    field(:runtime, :string)
    field(:status, :string, default: "pending")

    field(:lambda_function_name, :string)
    field(:lambda_function_handler, :string)
    field(:lambda_revision_id, :string)
    field(:lambda_last_update_status, :string)

    belongs_to(:account, Account)
    belongs_to(:creator, User, foreign_key: :creator_id, references: :id, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(lambda, attrs) do
    lambda
    |> cast(attrs, [
      :name,
      :description,
      :code,
      :language,
      :runtime,
      :status,
      :last_deployed_at,
      :last_executed_at,
      :account_id,
      :lambda_function_name,
      :lambda_function_handler,
      :lambda_revision_id,
      :lambda_last_update_status,
      :metadata
    ])
    |> validate_required([
      :account_id,
      :name,
      :status
    ])
    |> validate_inclusion(:status, ["active", "inactive", "pending"])
    |> validate_inclusion(:language, ["javascript"])
    |> validate_inclusion(:runtime, ["nodejs14.x"])
  end
end
