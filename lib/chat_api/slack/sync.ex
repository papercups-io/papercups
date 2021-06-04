defmodule ChatApi.Slack.Sync do
  require Logger

  alias ChatApi.{
    Conversations,
    Messages,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads
  }

  alias ChatApi.Customers.Customer
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.Users.User

  defmodule SyncableMessageInfo do
    defstruct [:message, :sender, :is_bot]

    @type t :: %__MODULE__{
            message: map(),
            sender: Customer.t() | User.t() | nil,
            is_bot: boolean()
          }
  end

  @spec get_syncable_slack_messages(map()) :: [SyncableMessageInfo.t()]
  def get_syncable_slack_messages(
        %{
          "type" => "message",
          "team" => team,
          "text" => _text,
          "thread_ts" => _thread_ts,
          "channel" => _slack_channel_id
        } = event
      ) do
    with %SlackAuthorization{access_token: _access_token} = authorization <-
           SlackAuthorizations.find_slack_authorization(%{
             team_id: team,
             type: "support"
           }) do
      get_syncable_slack_messages(authorization, event)
    else
      _ -> []
    end
  end

  @spec get_syncable_slack_messages(any(), map()) :: [SyncableMessageInfo.t()]
  def get_syncable_slack_messages(
        %SlackAuthorization{access_token: access_token} = authorization,
        %{
          "type" => "message",
          "text" => _text,
          "team" => _team,
          "thread_ts" => thread_ts,
          "channel" => slack_channel_id
        } = _event
      ) do
    with :ok <- Slack.Validation.validate_channel_supported(authorization, slack_channel_id),
         {:ok, response} <-
           Slack.Client.retrieve_conversation_replies(slack_channel_id, thread_ts, access_token),
         {:ok, slack_messages} <- Slack.Extractor.extract_slack_messages(response) do
      Enum.map(slack_messages, fn msg ->
        %SyncableMessageInfo{
          message: msg,
          sender: Slack.Helpers.get_sender_info(authorization, msg),
          is_bot: Slack.Helpers.is_bot_message?(msg)
        }
      end)
    else
      _ -> []
    end
  end

  @spec should_sync_slack_messages?([SyncableMessageInfo.t()]) :: boolean()
  def should_sync_slack_messages?([initial | replies]) do
    is_valid_initial =
      case initial do
        %{is_bot: true} -> true
        %{sender: %User{}} -> true
        _ -> false
      end

    has_customer_reply =
      Enum.any?(replies, fn reply ->
        case reply do
          %{is_bot: false, sender: %Customer{}} -> true
          _ -> false
        end
      end)

    is_valid_initial && has_customer_reply
  end

  # TODO: do a better job distinguishing between Slack webhook event and Slack message payload
  @spec sync_slack_message_thread([SyncableMessageInfo.t()], SlackAuthorization.t(), map()) ::
          any()
  def sync_slack_message_thread(
        syncable_message_items,
        %SlackAuthorization{account_id: account_id} = authorization,
        %{
          "type" => "message",
          "thread_ts" => thread_ts,
          "channel" => slack_channel_id
        } = _event
      ) do
    # TODO: make it possible to pass in customer manually
    with %{sender: %Customer{} = customer} <-
           Enum.find(syncable_message_items, fn item ->
             case item do
               %{is_bot: false, sender: %Customer{}} -> true
               _ -> false
             end
           end),
         {:ok, conversation} <-
           Conversations.create_conversation(%{
             account_id: account_id,
             customer_id: customer.id,
             source: "slack"
           }),
         {:ok, _slack_conversation_thread} <-
           SlackConversationThreads.create_slack_conversation_thread(%{
             slack_channel: slack_channel_id,
             slack_thread_ts: thread_ts,
             account_id: account_id,
             conversation_id: conversation.id
           }) do
      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()
      |> Conversations.Notification.broadcast_new_conversation_to_customer!()
      |> Conversations.Notification.notify(:webhooks, event: "conversation:created")

      Enum.map(syncable_message_items, fn
        %{
          message: %{"text" => text} = message,
          sender: sender
        } ->
          sender =
            case sender do
              nil -> create_or_update_sender!(message, authorization)
              sender -> sender
            end

          message_sender_params =
            case sender do
              %User{id: user_id} -> %{"user_id" => user_id}
              %Customer{id: customer_id} -> %{"customer_id" => customer_id}
              # TODO: if no sender exists yet, create one!
              _ -> raise "Unexpected sender #{inspect(sender)}"
            end

          %{
            "body" => Slack.Helpers.sanitize_slack_message(text, authorization),
            "conversation_id" => conversation.id,
            "account_id" => account_id,
            "sent_at" => message |> Map.get("ts") |> Slack.Helpers.slack_ts_to_utc(),
            "source" => "slack"
          }
          |> Map.merge(message_sender_params)
          |> Messages.create_and_fetch!()
          |> Messages.Notification.broadcast_to_customer!()
          |> Messages.Notification.broadcast_to_admin!()
          |> Messages.Notification.notify(:webhooks)
          # NB: we need to make sure the messages are created in the correct order, so we set async: false
          |> Messages.Notification.notify(:slack, async: false)
          # TODO: not sure we need to do this on every message
          |> Messages.Helpers.handle_post_creation_hooks()

        _ ->
          nil
      end)
    end
  end

  @spec create_or_update_sender!(map(), SlackAuthorization.t()) :: Customer.t()
  def create_or_update_sender!(%{"user" => slack_user_id}, authorization) do
    case Slack.Helpers.create_or_update_customer_from_slack_user_id(authorization, slack_user_id) do
      {:ok, customer} -> customer
      error -> raise "Failed to create customer from Slack user token: #{inspect(error)}"
    end
  end

  def create_or_update_sender!(%{"bot_id" => slack_bot_id}, authorization) do
    case Slack.Helpers.create_or_update_customer_from_slack_bot_id(authorization, slack_bot_id) do
      {:ok, customer} -> customer
      error -> raise "Failed to create customer from Slack bot token: #{inspect(error)}"
    end
  end
end
