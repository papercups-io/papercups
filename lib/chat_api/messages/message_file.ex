defmodule ChatApi.Messages.MessageFile do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Messages.Message
  alias ChatApi.Files.FileUpload
  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          # Foreign keys
          account_id: Ecto.UUID.t(),
          account: any(),
          file_id: Ecto.UUID.t(),
          file: any(),
          message_id: Ecto.UUID.t(),
          message: any(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "message_files" do
    belongs_to(:message, Message)
    belongs_to(:file, FileUpload, foreign_key: :file_id)
    belongs_to(:account, Account)
    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [
      :account_id,
      :message_id,
      :file_id
    ])
    |> validate_required([:account_id, :message_id, :file_id])
  end
end
