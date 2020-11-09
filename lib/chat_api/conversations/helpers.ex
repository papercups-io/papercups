defmodule ChatApi.Conversations.Helpers do
  @moduledoc """
  Helper methods for Conversations context.
  """

  alias ChatApi.Slack

  @spec send_conversation_state_update(Conversation.t(), map()) ::
          {:ok, String.t()} | {:error, String.t()}
  def send_conversation_state_update(conversation, state) do
    case get_conversation_state_message(state) do
      nil ->
        # TODO: should we use an atom here (e.g. :invalid_state),
        # or a more descriptive string (e.g. "Invalid state: #{inspect(state)}")?
        {:error, "state_invalid"}

      conversation_state_message ->
        Slack.send_conversation_message_alert(
          conversation.id,
          conversation_state_message,
          type: :conversation_update
        )

        {:ok, conversation_state_message}
    end
  end

  @spec send_multiple_archived_updates([Conversation.t()]) :: list()
  def send_multiple_archived_updates(conversations) do
    state = %{"state" => "archived"}

    Enum.map(conversations, fn conversation ->
      send_conversation_state_update(conversation, state)
    end)
  end

  @spec get_conversation_state_message(map()) :: String.t() | nil
  defp get_conversation_state_message(state) do
    case state do
      %{"status" => "open"} ->
        ":outbox_tray: This conversation has been reopened."

      %{"status" => "closed"} ->
        ":white_check_mark: This conversation has been closed."

      %{"state" => "archived"} ->
        ":file_cabinet: This conversation has been archived."

      %{"state" => "deleted"} ->
        ":wastebasket: This conversation has been deleted."

      %{"priority" => "priority"} ->
        ":star: This conversation has been prioritized."

      %{"priority" => "not_priority"} ->
        ":ok_hand: This conversation has been de-prioritized."

      _ ->
        nil
    end
  end
end
