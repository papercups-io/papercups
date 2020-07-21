defmodule ChatApi.SlackConversationThreads.SlackConversationThread do
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

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(slack_conversation_thread, attrs) do
    slack_conversation_thread
    |> cast(attrs, [:slack_channel, :slack_thread_ts, :conversation_id, :account_id])
    |> validate_required([:slack_channel, :slack_thread_ts, :conversation_id, :account_id])
  end
end
