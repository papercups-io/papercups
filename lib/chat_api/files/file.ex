defmodule ChatApi.Files.FileUpload do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Customers.Customer
  alias ChatApi.Users.User
  alias ChatApi.Messages.MessageFile

  @type t :: %__MODULE__{
          filename: String.t(),
          file_url: String.t(),
          content_type: String.t(),
          unique_filename: String.t() | nil,
          # Foreign keys
          account_id: Ecto.UUID.t(),
          account: any(),
          customer_id: Ecto.UUID.t(),
          customer: any(),
          user_id: integer(),
          user: any(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "files" do
    field(:filename, :string)
    field(:file_url, :string)
    field(:unique_filename, :string)
    field(:content_type, :string)

    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    belongs_to(:user, User, type: :integer)

    has_many(:message_files, MessageFile, foreign_key: :file_id)
    has_many(:messages, through: [:message_files, :messages])

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [
      :account_id,
      :user_id,
      :customer_id,
      :filename,
      :file_url,
      :unique_filename,
      :content_type
    ])
    |> validate_required([:account_id, :filename, :file_url, :content_type])
  end
end
