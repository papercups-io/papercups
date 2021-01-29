defmodule ChatApi.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Attachments.Attachment

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "uploads" do
    field(:filename, :string)
    field(:file_url, :string)
    field(:unique_filename, :string)
    field(:content_type, :string)

    # TODO: add account/user/customer associations

    has_many(:attachments, Attachment)
    has_many(:messages, through: [:attachments, :messages])

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :file_url, :unique_filename, :content_type])
    |> validate_required([:filename, :file_url, :content_type])
  end
end
