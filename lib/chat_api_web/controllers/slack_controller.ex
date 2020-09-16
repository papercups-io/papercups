defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.{
    Messages,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads
  }

  action_fallback ChatApiWeb.FallbackController

  def oauth(conn, %{"code" => code}) do
    Logger.info("Code from Slack OAuth: #{inspect(code)}")

    # TODO: improve error handling!
    {:ok, response} = Slack.get_access_token(code)

    Logger.info("Slack OAuth response: #{inspect(response)}")

    %{body: body} = response

    if Map.get(body, "ok") do
      with %{account_id: account_id} <- conn.assigns.current_user,
           %{
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

        SlackAuthorizations.create_or_update(account_id, params)

        json(conn, %{data: %{ok: true}})
      else
        _ ->
          raise "Unrecognized OAuth response"
      end
    else
      raise "OAuth access denied"
    end
  end

  def authorization(conn, _payload) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      auth = SlackAuthorizations.get_authorization_by_account(account_id)

      case auth do
        nil ->
          json(conn, %{data: nil})

        _ ->
          json(conn, %{
            data: %{
              created_at: auth.inserted_at,
              channel: auth.channel,
              configuration_url: auth.configuration_url,
              team_name: auth.team_name
            }
          })
      end
    end
  end

  def webhook(conn, payload) do
    Logger.debug("Payload from Slack webhook: #{inspect(payload)}")

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
         %{
           "type" => "message",
           "text" => text,
           "thread_ts" => thread_ts,
           "channel" => channel,
           "user" => user_id
         } = event
       ) do
    Logger.debug("Handling Slack event: #{inspect(event)}")

    with {:ok, conversation} <- get_thread_conversation(thread_ts, channel) do
      %{id: conversation_id, account_id: account_id} = conversation
      sender_id = Slack.get_sender_id(conversation, user_id)

      params = %{
        "body" => text,
        "conversation_id" => conversation_id,
        "account_id" => account_id,
        "user_id" => sender_id
      }

      params
      |> Messages.create_and_fetch!()
      |> Messages.broadcast_to_conversation!()
      |> Messages.notify(:webhooks)
    end
  end

  defp handle_event(_), do: nil

  defp get_thread_conversation(thread_ts, channel) do
    case SlackConversationThreads.get_by_slack_thread_ts(thread_ts, channel) do
      %{conversation: conversation} -> {:ok, conversation}
      _ -> {:error, "Not found"}
    end
  end
end
