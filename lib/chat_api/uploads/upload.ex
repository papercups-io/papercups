defmodule ChatApi.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Messages.Message

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "upload" do
    field(:filename, :string)
    field(:file_url, :string)
    field(:content_type, :string)
    belongs_to(:message, Message)

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :file_url, :message_id, :content_type])
    |> validate_required([:filename, :file_url, :message_id, :content_type])
  end
end
