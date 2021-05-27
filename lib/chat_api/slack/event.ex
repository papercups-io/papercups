defmodule ChatApi.Slack.Event do
  require Logger

  alias ChatApi.{
    Companies,
    Conversations,
    Messages,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads
  }

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @spec handle_payload(map()) :: any()
  def handle_payload(
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

  def handle_payload(_), do: nil

  @spec handle_event(map()) :: any()
  def handle_event(%{"bot_id" => _bot_id} = _event) do
    # Don't do anything on bot events for now
    nil
  end

  def handle_event(%{"type" => "message", "text" => ""} = _event) do
    # Don't do anything for blank messages (e.g. when only an attachment is sent)
    # TODO: add better support for image/file attachments
    nil
  end

  def handle_event(
        %{
          "type" => "message",
          "text" => text,
          "thread_ts" => thread_ts,
          "channel" => slack_channel_id,
          "user" => slack_user_id
        } = event
      ) do
    Logger.debug("Handling Slack message reply event: #{inspect(event)}")

    with {:ok, conversation} <- find_thread_conversation(thread_ts, slack_channel_id),
         %{account_id: account_id, id: conversation_id} <- conversation,
         primary_reply_authorization <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"}) do
      if Slack.Helpers.is_primary_channel?(primary_reply_authorization, slack_channel_id) do
        text
        |> Slack.Helpers.parse_message_type_params()
        |> Map.merge(%{
          "body" => Slack.Helpers.sanitize_slack_message(text, primary_reply_authorization),
          "conversation_id" => conversation_id,
          "account_id" => account_id,
          "source" => "slack",
          "sent_at" => event |> Map.get("ts") |> Slack.Helpers.slack_ts_to_utc(),
          "user_id" =>
            Slack.Helpers.get_admin_sender_id(
              primary_reply_authorization,
              slack_user_id,
              conversation.assignee_id
            )
        })
        |> Messages.create_and_fetch!()
        |> Messages.Notification.broadcast_to_customer!()
        |> Messages.Notification.broadcast_to_admin!()
        |> Messages.Notification.notify(:webhooks)
        |> Messages.Notification.notify(:slack_support_channel)
        |> Messages.Notification.notify(:slack_company_channel)
        |> Messages.Notification.notify(:conversation_reply_email)
        |> Messages.Notification.notify(:gmail)
        |> Messages.Notification.notify(:sms)
        |> Messages.Notification.notify(:mattermost)
        |> Messages.Helpers.handle_post_creation_hooks()
      else
        case SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}) do
          nil ->
            nil

          authorization ->
            authorization
            |> Slack.Helpers.format_sender_id!(slack_user_id, slack_channel_id)
            |> Map.merge(%{
              "body" => Slack.Helpers.sanitize_slack_message(text, authorization),
              "conversation_id" => conversation_id,
              "account_id" => account_id,
              "sent_at" => event |> Map.get("ts") |> Slack.Helpers.slack_ts_to_utc(),
              "source" => "slack"
            })
            |> Messages.create_and_fetch!()
            |> Messages.Notification.broadcast_to_customer!()
            |> Messages.Notification.broadcast_to_admin!()
            |> Messages.Notification.notify(:webhooks)
            |> Messages.Notification.notify(:slack)
            |> Messages.Helpers.handle_post_creation_hooks()
        end
      end
    else
      # If an existing conversation is not found, we check to see if this is a reply to a bot
      # or agent message. At the moment, we want to start a new thread for replies to these messages.
      {:error, :not_found} ->
        handle_reply_to_unknown_thread(event)

      error ->
        error
    end
  end

  # NB: this currently listens for the Papercups app being added to a Slack channel.
  # At the moment, it doesn't do anything. But in the future, we may auto-create a
  # `company` record based on the Slack channel info (if this use case is common enough)
  def handle_event(
        %{
          "type" => "message",
          # Public channels use subtype "channel_join", while private channels use "group_join"
          "subtype" => subtype,
          "user" => slack_user_id,
          "channel" => slack_channel_id,
          "inviter" => _slack_inviter_id
        } = event
      )
      when subtype in ["channel_join", "group_join"] do
    Logger.info("Slack channel_join/group_join event detected:")
    Logger.info(inspect(event))

    with %{account_id: account_id, access_token: access_token, channel_id: channel_id} <-
           SlackAuthorizations.find_slack_authorization(%{
             bot_user_id: slack_user_id,
             type: "support"
           }),
         # This validates that the channel doesn't match the initially connected channel on
         # the `slack_authorization` record, since we currently treat that channel slightly differently
         true <- channel_id != slack_channel_id,
         :ok <- Slack.Validation.validate_no_existing_company(account_id, slack_channel_id),
         {:ok, response} <- Slack.Client.retrieve_channel_info(slack_channel_id, access_token),
         {:ok, channel} <- Slack.Extractor.extract_slack_channel(response),
         %{"name" => name, "purpose" => purpose, "topic" => topic} <- channel do
      company = %{
        # Set default company name to Slack channel name
        name: name,
        description: purpose["value"] || topic["value"],
        account_id: account_id,
        slack_channel_name: "##{name}",
        slack_channel_id: slack_channel_id
      }

      Slack.Helpers.send_internal_notification(
        "Papercups app was added to Slack channel `##{name}` for account `#{account_id}`"
      )

      # TODO: should we do this? might make onboarding a bit easier, but would also set up
      # companies with "weird" names (i.e. in the format of a Slack channel name)
      {:ok, result} = Companies.create_company(company)
      Logger.info("Successfully auto-created company:")
      Logger.info(inspect(result))
    end
  end

  # TODO: ignore message if it's from a bot?
  def handle_event(
        %{
          "type" => "message",
          "text" => _text,
          "team" => team,
          "channel" => slack_channel_id,
          "user" => slack_user_id,
          "ts" => _ts
        } = event
      ) do
    Logger.debug("Handling Slack new message event: #{inspect(event)}")

    with %SlackAuthorization{} = authorization <-
           SlackAuthorizations.find_slack_authorization(%{team_id: team, type: "support"}),
         %{sync_all_incoming_threads: true} <-
           SlackAuthorizations.get_authorization_settings(authorization),
         # TODO: remove after debugging!
         :ok <- Logger.info("Handling Slack new message event: #{inspect(event)}"),
         :ok <- Slack.Validation.validate_channel_supported(authorization, slack_channel_id),
         :ok <- Slack.Validation.validate_non_admin_user(authorization, slack_user_id) do
      create_new_conversation_from_slack_message(event, authorization)
    end
  end

  def handle_event(
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
    Logger.info("Handling Slack reaction event: #{inspect(event)}")

    with :ok <- Slack.Validation.validate_no_existing_thread(channel, ts),
         {:ok, account_id} <- find_account_id_by_support_channel(channel),
         %SlackAuthorization{access_token: access_token} = authorization <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}),
         %{sync_by_emoji_tagging: true} <-
           SlackAuthorizations.get_authorization_settings(authorization),
         {:ok, response} <- Slack.Client.retrieve_message(channel, ts, access_token),
         {:ok, message} <- Slack.Extractor.extract_slack_message(response) do
      Logger.info("Slack emoji reaction detected:")
      Logger.info(inspect(event))

      # The message from the conversations.history API doesn't include the channel, so we add it manually
      message
      |> Map.merge(%{"channel" => channel})
      |> handle_emoji_reaction_event()
    end
  end

  def handle_event(_), do: nil

  # TODO: DRY this up with the message event handler above, for now the only difference between this one
  # and that one is: this handler allows admin users to create threads via Slack support channels
  @spec handle_emoji_reaction_event(map()) :: any()
  def handle_emoji_reaction_event(
        %{
          "type" => "message",
          "text" => _text,
          "team" => team,
          "channel" => slack_channel_id,
          "user" => _slack_user_id,
          "ts" => _ts
        } = event
      ) do
    with authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }),
         :ok <- Slack.Validation.validate_channel_supported(authorization, slack_channel_id) do
      # TODO: sync whole message thread if there are multiple messages already
      # (See `Slack.Sync.sync_slack_message_thread(messages, authorization, event)`)
      create_new_conversation_from_slack_message(event, authorization)
    end
  end

  def handle_emoji_reaction_event(_), do: nil

  @spec handle_reply_to_unknown_thread(map()) :: any()
  def handle_reply_to_unknown_thread(
        %{
          "type" => "message",
          "text" => _text,
          "team" => team,
          "thread_ts" => _thread_ts,
          "channel" => _slack_channel_id,
          "user" => _slack_user_id
        } = event
      ) do
    with %SlackAuthorization{} = authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }),
         [_ | _] = messages <- Slack.Sync.get_syncable_slack_messages(authorization, event),
         true <- Slack.Sync.should_sync_slack_messages?(messages) do
      Slack.Sync.sync_slack_message_thread(messages, authorization, event)
    end
  end

  def handle_reply_to_unknown_thread(_event), do: nil

  # TODO: move to Slack.Helpers?
  @spec create_new_conversation_from_slack_message(map(), SlackAuthorization.t()) ::
          Message.t() | {:error, any()}
  def create_new_conversation_from_slack_message(
        %{
          "type" => "message",
          "text" => text,
          "channel" => slack_channel_id,
          "ts" => ts
        } = event,
        %SlackAuthorization{account_id: account_id} = authorization
      ) do
    # NB: not ideal, but this may treat an internal/admin user as a "customer",
    # because at the moment all conversations must have a customer associated with them
    with {:ok, customer} <-
           Slack.Helpers.create_or_update_customer_from_slack_event(authorization, event),
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
             body: Slack.Helpers.sanitize_slack_message(text, authorization),
             sent_at: Slack.Helpers.slack_ts_to_utc(ts),
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
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> Conversations.Notification.broadcast_new_conversation_to_customer!()
      |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

      Messages.get_message!(message.id)
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:webhooks)
      # TODO: should we make this configurable? Or only do it from private channels?
      # (Leaving this enabled for the emoji reaction use case, since it's an explicit action
      # as opposed to the auto-syncing that occurs above for all new messages)
      |> Messages.Notification.notify(:slack, metadata: authorization.metadata)
    end
  end

  @spec find_thread_conversation(binary(), binary()) ::
          {:ok, Conversation.t()} | {:error, :not_found}
  defp find_thread_conversation(thread_ts, channel) do
    case SlackConversationThreads.get_by_slack_thread_ts(thread_ts, channel) do
      %{conversation: conversation} -> {:ok, conversation}
      _ -> {:error, :not_found}
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
end
