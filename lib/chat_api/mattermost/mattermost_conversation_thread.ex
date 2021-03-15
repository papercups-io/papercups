defmodule ChatApi.Mattermost.MattermostConversationThread do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation

  @type t :: %__MODULE__{
          mattermost_channel_id: String.t() | nil,
          mattermost_post_root_id: String.t() | nil,
          # Relations
          account_id: any(),
          account: any(),
          conversation_id: any(),
          conversation: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "mattermost_conversation_threads" do
    field(:mattermost_channel_id, :string)
    field(:mattermost_post_root_id, :string)

    belongs_to(:account, Account)
    belongs_to(:conversation, Conversation)

    timestamps()
  end

  @doc false
  def changeset(mattermost_conversation_thread, attrs) do
    mattermost_conversation_thread
    |> cast(attrs, [
      :mattermost_channel_id,
      :mattermost_post_root_id,
      :conversation_id,
      :account_id
    ])
    |> validate_required([
      :mattermost_channel_id,
      :mattermost_post_root_id,
      :conversation_id,
      :account_id
    ])
  end
end
