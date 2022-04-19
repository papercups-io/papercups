defmodule ChatApi.Google.GmailConversationThread do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation

  @type t :: %__MODULE__{
          gmail_thread_id: String.t(),
          gmail_initial_subject: String.t() | nil,
          last_gmail_message_id: String.t() | nil,
          last_gmail_history_id: String.t() | nil,
          last_synced_at: DateTime.t(),
          metadata: any(),
          # Foreign keys
          account_id: Ecto.UUID.t(),
          conversation_id: Ecto.UUID.t(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gmail_conversation_threads" do
    field(:gmail_thread_id, :string, null: false)
    field(:gmail_initial_subject, :string)
    field(:last_gmail_message_id, :string)
    field(:last_gmail_history_id, :string)
    field(:last_synced_at, :utc_datetime)
    field(:metadata, :map)

    belongs_to(:account, Account)
    belongs_to(:conversation, Conversation)

    timestamps()
  end

  @doc false
  def changeset(google_authorization, attrs) do
    google_authorization
    |> cast(attrs, [
      :gmail_thread_id,
      :gmail_initial_subject,
      :last_gmail_message_id,
      :last_gmail_history_id,
      :last_synced_at,
      :metadata,
      :conversation_id,
      :account_id
    ])
    |> validate_required([:gmail_thread_id, :conversation_id, :account_id])
  end
end
