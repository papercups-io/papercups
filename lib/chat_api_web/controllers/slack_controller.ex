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

  alias ChatApi.SlackAuthorizations.SlackAuthorization

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
      %{"event" => _event, "is_ext_shared_channel" => true} ->
        handle_payload(payload)
        send_resp(conn, 200, "")

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

  defp handle_payload(
         %{
           "event" => event,
           "team_id" => team,
           "is_ext_shared_channel" => true
         } = _payload
       ) do
    # NB: this is a bit of a hack -- we override the "team" id in the "event" payload
    # to match the "team" where the Papercups app is installed
    event
    |> Map.merge(%{"team" => team})
    |> handle_event()
  end

  defp handle_payload(_), do: nil

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
           "channel" => slack_channel_id,
           "user" => slack_user_id
         } = event
       ) do
    Logger.debug("Handling Slack message reply event: #{inspect(event)}")

    with {:ok, conversation} <- get_thread_conversation(thread_ts, slack_channel_id),
         %{account_id: account_id, id: conversation_id} <- conversation,
         primary_reply_authorization <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"}) do
      if Slack.Helpers.is_primary_channel?(primary_reply_authorization, slack_channel_id) do
        %{
          "body" => text,
          "conversation_id" => conversation_id,
          "account_id" => account_id,
          "source" => "slack",
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
        |> Messages.Notification.notify(:slack_support_channel)
        |> Messages.Notification.notify(:slack_company_channel)
        |> Messages.Helpers.handle_post_creation_conversation_updates()
      else
        case SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}) do
          nil ->
            nil

          authorization ->
            authorization
            |> Slack.Helpers.format_sender_id!(slack_user_id, slack_channel_id)
            |> Map.merge(%{
              "body" => text,
              "conversation_id" => conversation_id,
              "account_id" => account_id,
              "source" => "slack"
            })
            |> Messages.create_and_fetch!()
            |> Messages.Notification.broadcast_to_conversation!()
            |> Messages.Notification.notify(:webhooks)
            |> Messages.Notification.notify(:slack)
            |> Messages.Helpers.handle_post_creation_conversation_updates()
        end
      end
    end
  end

  defp handle_event(
         %{
           "type" => "message",
           "text" => text,
           "team" => team,
           "channel" => slack_channel_id,
           "user" => slack_user_id,
           "ts" => ts
         } = event
       ) do
    Logger.debug("Handling Slack new message event: #{inspect(event)}")

    with %{account_id: account_id} = authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }),
         :ok <- validate_channel_supported(authorization, slack_channel_id),
         :ok <- validate_non_admin_user(authorization, slack_user_id),
         {:ok, customer} <-
           Slack.Helpers.create_or_update_customer_from_slack_user_id(
             authorization,
             slack_user_id,
             slack_channel_id
           ),
         # TODO: should the conversation + thread + message all be handled in a transaction?
         # Probably yes at some point, but for now... not too big a deal ¯\_(ツ)_/¯
         # TODO: should we handle default assignment here as well?
         {:ok, conversation} <-
           Conversations.create_conversation(%{
             account_id: account_id,
             customer_id: customer.id,
             source: "slack"
           }),
         {:ok, message} <-
           Messages.create_message(%{
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             body: text,
             source: "slack"
           }),
         {:ok, _slack_conversation_thread} <-
           SlackConversationThreads.create_slack_conversation_thread(%{
             slack_channel: slack_channel_id,
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

  defp handle_event(
         %{
           "type" => "reaction_added",
           "reaction" => "eyes",
           "user" => _user,
           "item" => %{
             "channel" => channel,
             "ts" => ts,
             "type" => "message"
           }
         } = event
       ) do
    Logger.debug("Handling Slack reaction event: #{inspect(event)}")

    with :ok <- validate_no_existing_thread(channel, ts),
         {:ok, account_id} <- find_account_id_by_support_channel(channel),
         %{access_token: access_token} <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}),
         {:ok, response} <- Slack.Client.retrieve_message(channel, ts, access_token),
         {:ok, message} <- Slack.Helpers.extract_slack_message(response) do
      Logger.info("Slack emoji reaction detected:")
      Logger.info(inspect(event))

      # The message from the conversations.history API doesn't include the channel, so we add it manually
      message
      |> Map.merge(%{"channel" => channel})
      |> handle_emoji_reaction_event()
    end
  end

  # NB: this currently listens for the Papercups app being added to a Slack channel.
  # At the moment, it doesn't do anything. But in the future, we may auto-create a
  # `company` record based on the Slack channel info (if this use case is common enough)
  defp handle_event(
         %{
           "type" => "message",
           "subtype" => "group_join",
           "user" => slack_user_id,
           "channel" => slack_channel_id
           #  "inviter" => slack_inviter_id
         } = event
       ) do
    Logger.info("Slack group_join event detected:")
    Logger.info(inspect(event))

    with %{account_id: account_id, access_token: access_token} <-
           SlackAuthorizations.find_slack_authorization(%{
             bot_user_id: slack_user_id,
             type: "support"
           }),
         :ok <- validate_no_existing_company(account_id, slack_channel_id),
         {:ok, response} <- Slack.Client.retrieve_channel_info(slack_channel_id, access_token),
         {:ok, channel} <- Slack.Helpers.extract_slack_channel(response),
         %{"name" => name, "purpose" => purpose, "topic" => topic} <- channel do
      company = %{
        # Set default company name to Slack channel name
        name: name,
        description: purpose["value"] || topic["value"],
        account_id: account_id,
        slack_channel_name: "##{name}",
        slack_channel_id: slack_channel_id
      }

      Logger.info("Papercups app added to Slack channel: ##{name}")
      # TODO: should we do this? might make onboarding a bit easier, but would also set up
      # companies with "weird" names (i.e. in the format of a Slack channel name)
      Logger.info("Would have created company with fields:")
      Logger.info(inspect(company))
    end
  end

  defp handle_event(_), do: nil

  # TODO: DRY this up with the message event handler above, for now the only difference between this one
  # and that one is: this handler allows admin users to create threads via Slack support channels
  defp handle_emoji_reaction_event(
         %{
           "type" => "message",
           "text" => text,
           "team" => team,
           "channel" => slack_channel_id,
           "user" => slack_user_id,
           "ts" => ts
         } = _event
       ) do
    with %{account_id: account_id} = authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }),
         :ok <- validate_channel_supported(authorization, slack_channel_id),
         # NB: not ideal, but this may treat an internal/admin user as a "customer",
         # because at the moment all conversations must have a customer associated with them
         {:ok, customer} <-
           Slack.Helpers.create_or_update_customer_from_slack_user_id(
             authorization,
             slack_user_id,
             slack_channel_id
           ),
         # TODO: should the conversation + thread + message all be handled in a transaction?
         # Probably yes at some point, but for now... not too big a deal ¯\_(ツ)_/¯
         # TODO: should we handle default assignment here as well?
         {:ok, conversation} <-
           Conversations.create_conversation(%{
             account_id: account_id,
             customer_id: customer.id,
             source: "slack"
           }),
         {:ok, message} <-
           Messages.create_message(%{
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             body: text,
             source: "slack"
           }),
         {:ok, _slack_conversation_thread} <-
           SlackConversationThreads.create_slack_conversation_thread(%{
             slack_channel: slack_channel_id,
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

  defp get_thread_conversation(thread_ts, channel) do
    case SlackConversationThreads.get_by_slack_thread_ts(thread_ts, channel) do
      %{conversation: conversation} -> {:ok, conversation}
      _ -> {:error, "Not found"}
    end
  end

  @spec find_account_id_by_support_channel(binary()) :: {:ok, binary()} | {:error, :not_found}
  defp find_account_id_by_support_channel(slack_channel_id) do
    case ChatApi.Companies.find_by_slack_channel(slack_channel_id) do
      %{account_id: account_id} ->
        {:ok, account_id}

      _ ->
        case SlackAuthorizations.find_slack_authorization(%{
               channel_id: slack_channel_id,
               type: "support"
             }) do
          %{account_id: account_id} -> {:ok, account_id}
          _ -> {:error, :not_found}
        end
    end
  end

  @spec validate_non_admin_user(any(), binary()) :: :ok | :error
  defp validate_non_admin_user(authorization, slack_user_id) do
    case Slack.Helpers.find_matching_user(authorization, slack_user_id) do
      nil -> :ok
      _match -> :error
    end
  end

  @spec validate_channel_supported(any(), binary()) :: :ok | :error
  defp validate_channel_supported(
         %SlackAuthorization{channel_id: slack_channel_id},
         slack_channel_id
       ),
       do: :ok

  defp validate_channel_supported(
         %SlackAuthorization{account_id: account_id},
         slack_channel_id
       ) do
    case ChatApi.Companies.find_by_slack_channel(account_id, slack_channel_id) do
      nil -> :error
      _company -> :ok
    end
  end

  @spec validate_no_existing_company(binary(), binary()) :: :ok | :error
  def validate_no_existing_company(account_id, slack_channel_id) do
    case ChatApi.Companies.find_by_slack_channel(account_id, slack_channel_id) do
      nil -> :ok
      _company -> :error
    end
  end

  @spec validate_no_existing_thread(binary(), binary()) :: :ok | :error
  def validate_no_existing_thread(channel, ts) do
    case SlackConversationThreads.exists?(%{"slack_thread_ts" => ts, "slack_channel" => channel}) do
      false -> :ok
      true -> :error
    end
  end

  @spec notify_slack(Plug.Conn.t()) :: Plug.Conn.t()
  defp notify_slack(conn) do
    with %{email: email} <- conn.assigns.current_user do
      # Putting in an async Task for now, since we don't care if this succeeds
      # or fails (and we also don't want it to block anything)
      Task.start(fn ->
        Slack.Notifications.log("#{email} successfully linked Slack!")
      end)
    end

    conn
  end
end
