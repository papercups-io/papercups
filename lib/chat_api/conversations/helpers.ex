defmodule ChatApi.Conversations.Helpers do
  @moduledoc false

  alias ChatApi.Slack

  def send_conversation_state_update(conversation, attrs) do
    conversation_state_message = get_conversation_state_message(attrs)

    if conversation_state_message do
      Slack.send_conversation_message_alert(
        conversation.id,
        conversation_state_message,
        type: :convo_update
      )

      {:ok, conversation_state_message}
    else
      {:error, "state_invalid"}
    end
  end

  defp get_conversation_state_message(state) do
    case state do
      %{"status" => "open"} ->
        "This conversation has been reopened."

      %{"status" => "closed"} ->
        "This conversation has been closed."

      %{"status" => "archived"} ->
        "This conversation has been archived."

      %{"status" => "deleted"} ->
        "This conversation has been deleted."

      %{"priority" => "priority"} ->
        "This conversation has been prioritized."

      %{"priority" => "not_priority"} ->
        "This conversation has been de-prioritized."

      _ ->
        nil
    end
  end
end
