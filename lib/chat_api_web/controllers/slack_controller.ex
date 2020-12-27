defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.{
    Conversations,
    Messages,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads
  }

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code} = params) do
    Logger.info("Code from Slack OAuth: #{inspect(code)}")
    # TODO: improve error handling!
    {:ok, response} = Slack.Client.get_access_token(code)

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
          webhook_url: webhook_url,
          type: Map.get(params, "type", "reply")
        }

        SlackAuthorizations.create_or_update(account_id, params)

        conn
        |> notify_slack()
        |> json(%{data: %{ok: true}})
      else
        _ ->
          raise "Unrecognized OAuth response"
      end
    else
      raise "OAuth access denied"
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, payload) do
    filters = %{type: Map.get(payload, "type", "reply")}

    conn
    |> Pow.Plug.current_user()
    |> Map.get(:account_id)
    |> SlackAuthorizations.get_authorization_by_account(filters)
    |> case do
      nil ->
        json(conn, %{data: nil})

      auth ->
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

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
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

  @spec channels(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def channels(conn, payload) do
    # TODO: figure out the best way to handle errors here... should we just return
    # an empty list of channels if the call fails, or indicate that an error occurred?
    with %{account_id: account_id} <- conn.assigns.current_user,
         filters <- %{type: Map.get(payload, "type", "support")},
         %{access_token: access_token} <-
           SlackAuthorizations.get_authorization_by_account(account_id, filters),
         {:ok, result} <- Slack.Client.list_channels(access_token),
         %{body: %{"ok" => true, "channels" => channels}} <- result do
      json(conn, %{data: channels})
    end
  end

  defp handle_event(%{"bot_id" => _bot_id} = _event) do
    # Don't do anything on bot events for now
    nil
  end

  defp handle_event(%{"type" => "message", "text" => ""} = _event) do
    # Don't do anything for blank messages (e.g. when only an attachment is sent)
    # TODO: add better support for image/file attachments
    nil
  end

  defp handle_event(
         %{
           "type" => "message",
           "text" => text,
           "thread_ts" => thread_ts,
           "channel" => channel,
           "user" => slack_user_id
         } = event
       ) do
    Logger.debug("Handling Slack event: #{inspect(event)}")

    with {:ok, conversation} <- get_thread_conversation(thread_ts, channel),
         %{account_id: account_id, id: conversation_id} <- conversation,
         primary_reply_authorization <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"}) do
      if Slack.Helpers.is_primary_channel?(primary_reply_authorization, channel) do
        %{
          "body" => text,
          "conversation_id" => conversation_id,
          "account_id" => account_id,
          "user_id" =>
            Slack.Helpers.get_admin_sender_id(
              primary_reply_authorization,
              slack_user_id,
              conversation.assignee_id
            )
        }
        |> Messages.create_and_fetch!()
        |> Messages.Notification.broadcast_to_conversation!()
        |> Messages.Notification.notify(:webhooks)
        |> Messages.Notification.notify(:slack_support_threads)
      else
        account_id
        |> SlackAuthorizations.get_authorization_by_account(%{type: "support"})
        |> Slack.Helpers.format_sender_id!(slack_user_id)
        |> Map.merge(%{
          "body" => text,
          "conversation_id" => conversation_id,
          "account_id" => account_id
        })
        |> Messages.create_and_fetch!()
        |> Messages.Notification.broadcast_to_conversation!()
        |> Messages.Notification.notify(:webhooks)
        |> Messages.Notification.notify(:slack)
      end
    end
  end

  defp handle_event(
         %{
           "type" => "message",
           "text" => text,
           "team" => team,
           "channel" => channel,
           "user" => slack_user_id,
           "ts" => ts
         } = _event
       ) do
    with %{account_id: account_id} = authorization <-
           ChatApi.SlackAuthorizations.find_slack_authorization(%{
             channel_id: channel,
             team_id: team,
             type: "support"
           }),
         {:ok, customer} <-
           Slack.Helpers.find_or_create_customer_from_slack_user_id(authorization, slack_user_id),
         # TODO: should the conversation + thread + message all be handled in a transaction?
         # Probably yes at some point, but for now... not too big a deal ¯\_(ツ)_/¯
         # TODO: should we handle default assignment here as well?
         {:ok, conversation} <-
           Conversations.create_conversation(%{
             account_id: account_id,
             customer_id: customer.id
           }),
         {:ok, message} <-
           Messages.create_message(%{
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             body: text
           }),
         {:ok, _slack_conversation_thread} <-
           ChatApi.SlackConversationThreads.create_slack_conversation_thread(%{
             slack_channel: channel,
             slack_thread_ts: ts,
             account_id: account_id,
             conversation_id: conversation.id
           }) do
      conversation
      |> Conversations.Notification.broadcast_conversation_to_admin!()
      |> Conversations.Notification.broadcast_conversation_to_customer!()

      Messages.get_message!(message.id)
      |> Messages.Notification.broadcast_to_conversation!()
      # notify primary channel only
      |> Messages.Notification.notify(:slack)
      |> Messages.Notification.notify(:webhooks)
    end
  end

  defp handle_event(_), do: nil

  defp get_thread_conversation(thread_ts, channel) do
    case SlackConversationThreads.get_by_slack_thread_ts(thread_ts, channel) do
      %{conversation: conversation} -> {:ok, conversation}
      _ -> {:error, "Not found"}
    end
  end

  @spec notify_slack(Conn.t()) :: Conn.t()
  defp notify_slack(conn) do
    with %{email: email} <- conn.assigns.current_user do
      # Putting in an async Task for now, since we don't care if this succeeds
      # or fails (and we also don't want it to block anything)
      Task.start(fn ->
        ChatApi.Slack.Notifications.log("#{email} successfully linked Slack!")
      end)
    end

    conn
  end
end
