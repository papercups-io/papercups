defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  alias ChatApi.{Chat, SlackConversationThreads}

  action_fallback ChatApiWeb.FallbackController

  def webhook(conn, payload) do
    IO.inspect("Payload from Slack webhook:")
    IO.inspect(payload)

    case payload do
      %{"event" => event} ->
        handle_event(event)
        send_resp(conn, 200, "")

      %{"challenge" => challenge} ->
        send_resp(conn, 200, challenge)

      _ ->
        send_resp(conn, 200, "")
    end
  end

  defp handle_event(%{"bot_id" => _bot_id} = _event) do
    # Don't do anything on bot events for now
    nil
  end

  defp handle_event(
         %{"type" => "message", "text" => text, "thread_ts" => thread_ts, "channel" => channel} =
           event
       ) do
    IO.inspect("Handling Slack event:")
    IO.inspect(event)

    thread = SlackConversationThreads.get_by_slack_thread_ts(thread_ts, channel)

    with conversation <- thread.conversation do
      %{id: conversation_id, account_id: account_id} = conversation

      params = %{
        "body" => text,
        "conversation_id" => conversation_id,
        "account_id" => account_id,
        # TODO: map Slack users to internal users? (hardcoding for now to test)
        "user_id" => 1
      }

      {:ok, message} = Chat.create_message(params)
      result = ChatApiWeb.MessageView.render("message.json", message: message)

      ChatApiWeb.Endpoint.broadcast!("conversation:" <> conversation.id, "shout", result)
    end
  end

  defp handle_event(_), do: nil
end
