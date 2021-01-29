defmodule ChatApi.Messages.MessageFile do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Messages.Message
  alias ChatApi.Files.FileUpload
  alias ChatApi.Accounts.Account

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
