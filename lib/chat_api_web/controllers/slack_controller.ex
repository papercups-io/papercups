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

  action_fallback ChatApiWeb.FallbackController

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code}) do
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
          webhook_url: webhook_url
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
           "user" => user_id
         } = event
       ) do
    Logger.debug("Handling Slack event: #{inspect(event)}")
    IO.inspect(event)
    # TODO: check if message is coming from support channel thread?
    # If yes, will need to notify other "main" Slack channel...
    with {:ok, conversation} <- get_thread_conversation(thread_ts, channel) do
      if Slack.Helpers.is_primary_channel?(conversation.account_id, channel) do
        %{
          "body" => text,
          "conversation_id" => conversation.id,
          "account_id" => conversation.account_id,
          "user_id" => Slack.Helpers.get_admin_sender_id(conversation, user_id)
        }
        |> Messages.create_and_fetch!()
        |> Messages.Notification.broadcast_to_conversation!()
        |> Messages.Notification.notify(:webhooks)
        |> Messages.Notification.notify(:slack_support_threads)
      else
        # Some duplication here, but probably more readable then if we tried to be clever
        conversation.account_id
        |> Slack.Helpers.format_sender_id!(user_id)
        |> Map.merge(%{
          "body" => text,
          "conversation_id" => conversation.id,
          "account_id" => conversation.account_id
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
           "channel" => channel,
           "user" => user_id,
           "ts" => ts
         } = event
       ) do
    # Just some test IDs from my local env
    support_channel_id = "C01HKUP8RPA"
    account_id = "2ebbad4c-b162-4ed2-aff5-eaf9ebf469a5"

    # TODO: have different "types" of slack_authorizations: "reply" and "support"?
    # here we check if this event matches the "support" auth/workspace + channel
    # (I'm assuming the event has a field for this!)

    if channel == support_channel_id do
      IO.inspect("!!! Handling NEW Slack event !!!")
      IO.inspect(event)

      with %{access_token: token} <- Slack.Helpers.get_slack_authorization(account_id),
           {:ok, %{body: %{"ok" => true, "user" => user}}} <-
             Slack.Client.retrieve_user_info(user_id, token),
           %{"real_name" => name, "tz" => time_zone, "profile" => %{"email" => email}} <- user do
        IO.inspect(email)
        IO.inspect(user)

        # TODO: move into a `find_or_create_by_email` method
        customer =
          case ChatApi.Customers.find_by_email(email, account_id) do
            nil ->
              {:ok, created} =
                ChatApi.Customers.create_customer(%{
                  account_id: account_id,
                  email: email,
                  name: name,
                  time_zone: time_zone,
                  first_seen: DateTime.utc_now(),
                  last_seen: DateTime.utc_now(),
                  # TODO: last_seen is stored as a date, while last_seen_at is stored as
                  # a datetime -- we should opt for datetime values whenever possible
                  last_seen_at: DateTime.utc_now()
                })

              IO.inspect("CREATED NEW CUSTOMER!")
              IO.inspect(created)

              created

            found ->
              IO.inspect(found)

              found
          end

        # TODO: check for existing conversation thread!
        # OR: check for existing conversation in channel with different thread ID???
        # TODO: maybe this logic here only worries about CREATING new conversations?

        # TODO: should the conversation + thread + message all be handled in a transaction???
        # Probably yes at some point, but for now... not too big a deal ¯\_(ツ)_/¯

        {:ok, conversation} =
          Conversations.create_conversation(%{
            account_id: account_id,
            customer_id: customer.id
          })

        IO.inspect("CONVERSATION!")
        IO.inspect(conversation)

        # TODO: create new slack_conversation_thread? (use `ts` field from message for `slack_thread_ts`)
        {:ok, slack_conversation_thread} =
          ChatApi.SlackConversationThreads.create_slack_conversation_thread(%{
            slack_channel: channel,
            slack_thread_ts: ts,
            account_id: account_id,
            conversation_id: conversation.id
          })

        IO.inspect("SLACK CONVERSATION THREAD!")
        IO.inspect(slack_conversation_thread)

        {:ok, message} =
          Messages.create_message(%{
            account_id: account_id,
            conversation_id: conversation.id,
            customer_id: customer.id,
            body: text
          })

        IO.inspect("MESSAGE!")
        IO.inspect(message)

        conversation
        |> Conversations.Notification.broadcast_conversation_to_admin!()
        |> Conversations.Notification.broadcast_conversation_to_customer!()

        Messages.get_message!(message.id)
        |> Messages.Notification.broadcast_to_conversation!()
        # notify primary channel only
        |> Messages.Notification.notify(:slack)
        |> Messages.Notification.notify(:webhooks)
      end

      # TODO: what happens here?
      # check if an account has a support_channel_id that matches
      # if channel matches a "support" channel:
      # get the "customer" info based on the user_id, and find or create a customer
      # spawn a new conversation with the provided message, linking to customer_id
      # handle default assignment?
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
