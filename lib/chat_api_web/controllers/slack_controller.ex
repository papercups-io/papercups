defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  alias ChatApi.{Chat, Slack, SlackAuthorizations, SlackConversationThreads}

  action_fallback ChatApiWeb.FallbackController

  def oauth(conn, %{"code" => code}) do
    IO.inspect("Code from Slack OAuth:")
    IO.inspect(code)

    {:ok, response} = Slack.get_access_token(code)
    %{body: body} = response

    if Map.get(body, "ok") do
      with %{
             "access_token" => access_token,
             "app_id" => app_id,
             "bot_user_id" => bot_user_id,
             "scope" => scope,
             "token_type" => token_type,
             "authed_user" => authed_user,
             "team" => team,
             "incoming_webhook" => incoming_webhook
           } <- body,
           %{"id" => authed_user_id} <- authed_user,
           %{"id" => team_id, "name" => team_name} <- team,
           %{
             "channel" => channel,
             "channel_id" => channel_id,
             "configuration_url" => configuration_url,
             "url" => webhook_url
           } <- incoming_webhook do
        # FIXME
        account_id = "eb504736-0f20-4978-98ff-1a82ae60b266"

        params = %{
          account_id: account_id,
          access_token: access_token,
          app_id: app_id,
          authed_user_id: authed_user_id,
          bot_user_id: bot_user_id,
          scope: scope,
          token_type: token_type,
          channel: channel,
          channel_id: channel_id,
          configuration_url: configuration_url,
          team_id: team_id,
          team_name: team_name,
          webhook_url: webhook_url
        }

        SlackAuthorizations.find_or_create(account_id, params)

        send_resp(conn, 200, "")
      else
        _ ->
          raise "Unrecognized OAuth response"
      end
    else
      raise "OAuth access denied"
    end
  end

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
      %{id: conversation_id, account_id: account_id, assignee_id: assignee_id} = conversation

      params = %{
        "body" => text,
        "conversation_id" => conversation_id,
        "account_id" => account_id,
        # TODO: map Slack users to internal users eventually?
        # (Currently we just assume the assignee is always the one responding)
        "user_id" => assignee_id
      }

      {:ok, message} = Chat.create_message(params)
      result = ChatApiWeb.MessageView.render("message.json", message: message)

      ChatApiWeb.Endpoint.broadcast!("conversation:" <> conversation.id, "shout", result)
    end
  end

  defp handle_event(_), do: nil
end
