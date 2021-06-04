defmodule ChatApi.SlackAuthorizations.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          sync_all_incoming_threads: boolean(),
          sync_by_emoji_tagging: boolean(),
          sync_trigger_emoji: String.t(),
          forward_synced_messages_to_reply_channel: boolean()
        }

  embedded_schema do
    field(:sync_all_incoming_threads, :boolean, default: true)
    field(:sync_by_emoji_tagging, :boolean, default: true)
    field(:sync_trigger_emoji, :string, default: "eyes")
    field(:forward_synced_messages_to_reply_channel, :boolean, default: true)
  end

  @spec changeset(any(), map()) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, [
      :sync_all_incoming_threads,
      :sync_by_emoji_tagging,
      :sync_trigger_emoji,
      :forward_synced_messages_to_reply_channel
    ])
  end
end
