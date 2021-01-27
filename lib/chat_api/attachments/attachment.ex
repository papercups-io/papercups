defmodule ChatApi.Attachments.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Messages.Message
  alias ChatApi.Uploads.Upload
  alias ChatApi.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "attachments" do
    belongs_to(:message, Message)
    belongs_to(:upload, Upload)
    belongs_to(:account, Account)
    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [
      :account_id,
      :message_id,
      :upload_id
    ])
    |> validate_required([:account_id, :message_id, :upload_id])
  end
end
