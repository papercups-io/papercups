defmodule ChatApi.Slack.SlackConversationThread do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Conversations.Conversation

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slack_conversation_threads" do
    field :slack_channel, :string
    field :slack_thread_ts, :string

    belongs_to(:account, Account)
    belongs_to(:conversation, Conversation)

    timestamps()
  end

  @doc false
  @spec changeset(any(), map()) :: Ecto.Changeset.t()
  def changeset(slack_conversation_thread, attrs) do
    slack_conversation_thread
    |> cast(attrs, [:slack_channel, :slack_thread_ts, :conversation_id, :account_id])
    |> validate_required([:slack_channel, :slack_thread_ts, :conversation_id, :account_id])
  end
end
