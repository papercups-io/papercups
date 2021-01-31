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

    with {:ok, conversation} <- get_thread_conversation(thread_ts, slack_channel_id),
         %{account_id: account_id, id: conversation_id} <- conversation,
         primary_reply_authorization <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"}) do
      if Slack.Helpers.is_primary_channel?(primary_reply_authorization, slack_channel_id) do
        %{
          "body" => Slack.Helpers.sanitize_slack_message(text, primary_reply_authorization),
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
        |> Messages.Notification.broadcast_to_customer!()
        |> Messages.Notification.broadcast_to_admin!()
        |> Messages.Notification.notify(:webhooks)
        |> Messages.Notification.notify(:slack_support_channel)
        |> Messages.Notification.notify(:slack_company_channel)
        |> Messages.Notification.notify(:conversation_reply_email)
        |> Messages.Helpers.handle_post_creation_conversation_updates()
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
              "source" => "slack"
            })
            |> Messages.create_and_fetch!()
            |> Messages.Notification.broadcast_to_customer!()
            |> Messages.Notification.broadcast_to_admin!()
            |> Messages.Notification.notify(:webhooks)
            |> Messages.Notification.notify(:slack)
            |> Messages.Helpers.handle_post_creation_conversation_updates()
        end
      end
    else
      # If an existing conversation is not found, we check to see if this is a reply to a bot message.
      # At the moment, we want to start a new thread for replies to bot messages.
      {:error, :not_found} ->
        handle_reply_to_bot_event(event)

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

    with authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }),
         # TODO: remove after debugging!
         :ok <- Logger.info("Handling Slack new message event: #{inspect(event)}"),
         :ok <- validate_channel_supported(authorization, slack_channel_id),
         :ok <- validate_non_admin_user(authorization, slack_user_id) do
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
         :ok <- validate_channel_supported(authorization, slack_channel_id) do
      create_new_conversation_from_slack_message(event, authorization)
    end
  end

  @spec handle_reply_to_bot_event(map()) :: any()
  def handle_reply_to_bot_event(
        %{
          "type" => "message",
          "text" => _text,
          "team" => team,
          "thread_ts" => thread_ts,
          "channel" => slack_channel_id,
          "user" => slack_user_id
        } = event
      ) do
    with %{access_token: access_token} = authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }),
         # TODO: remove after debugging!
         :ok <- Logger.info("Checking if message event is reply to bot: #{inspect(event)}"),
         :ok <- validate_channel_supported(authorization, slack_channel_id),
         {:ok, response} <-
           Slack.Client.retrieve_conversation_replies(slack_channel_id, thread_ts, access_token),
         {:ok, [initial_message | replies]} <- Slack.Helpers.extract_slack_messages(response),
         # TODO: support both bot messages AND messages from admin/internal users
         true <- Slack.Helpers.is_bot_message?(initial_message) do
      # Handle initial message first
      create_new_conversation_from_slack_message(
        %{
          "type" => "message",
          "text" => Map.get(initial_message, "text"),
          "channel" => slack_channel_id,
          # TODO: this will currently treat the bot as if it were the user...
          # We still need to add better support for bot messages
          "user" => Map.get(initial_message, "user", slack_user_id),
          "ts" => thread_ts
        },
        authorization
      )

      # Then, handle replies
      Enum.each(replies, fn msg ->
        # Wait 1s between each message so they don't have the same `inserted_at`
        # timestamp... in the future, we should start sorting by `sent_at` instead!
        Process.sleep(1000)

        handle_event(%{
          "type" => "message",
          "text" => Map.get(msg, "text"),
          "thread_ts" => thread_ts,
          "channel" => slack_channel_id,
          "user" => Map.get(msg, "user", slack_user_id)
        })
      end)
    end
  end

  def handle_reply_to_bot_event(_event), do: nil

  # TODO: move to Slack.Helpers?
  @spec create_new_conversation_from_slack_message(map(), SlackAuthorization.t()) ::
          Message.t() | {:error, any()}
  def create_new_conversation_from_slack_message(
        %{
          "type" => "message",
          "text" => text,
          "channel" => slack_channel_id,
          "user" => slack_user_id,
          "ts" => ts
        } = _event,
        %SlackAuthorization{account_id: account_id} = authorization
      ) do
    # NB: not ideal, but this may treat an internal/admin user as a "customer",
    # because at the moment all conversations must have a customer associated with them
    with {:ok, customer} <-
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
             body: Slack.Helpers.sanitize_slack_message(text, authorization),
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
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:webhooks)
      # TODO: should we make this configurable? Or only do it from private channels?
      # (Leaving this enabled for the emoji reaction use case, since it's an explicit action
      # as opposed to the auto-syncing that occurs above for all new messages)
      |> Messages.Notification.notify(:slack, authorization.metadata)
    end
  end

  defp get_thread_conversation(thread_ts, channel) do
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
end
