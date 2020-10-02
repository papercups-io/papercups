defmodule ChatApi.Tags.ConversationTag do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{Accounts.Account, Conversations.Conversation, Tags.Tag, Users.User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "conversation_tags" do
    belongs_to(:account, Account)
    belongs_to(:conversation, Conversation)
    belongs_to(:tag, Tag)
    belongs_to(:creator, User, foreign_key: :creator_id, references: :id, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:account_id, :conversation_id, :tag_id, :creator_id])
    |> validate_required([:account_id, :conversation_id, :tag_id])
  end
end
