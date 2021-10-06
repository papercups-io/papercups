defmodule ChatApi.Messages.Notification do
  @moduledoc """
  Notification handlers for messages
  """

  alias ChatApi.{EventSubscriptions, Lambdas}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.{Helpers, Message}
  alias ChatApi.Users.User

  require Logger

  @spec broadcast_to_customer!(Message.t()) :: Message.t()
  def broadcast_to_customer!(%Message{private: false} = message) do
    Logger.info(
      "Sending message notification: broadcast_to_customer! (message #{inspect(message.id)})"
    )

    message
    |> Helpers.get_conversation_topic()
    |> ChatApiWeb.Endpoint.broadcast!("shout", Helpers.format(message))

    message
  end

  def broadcast_to_customer!(message), do: message

  @spec broadcast_to_admin!(Message.t()) :: Message.t()
  def broadcast_to_admin!(%Message{} = message) do
    Logger.info(
      "Sending message notification: broadcast_to_admin! (message #{inspect(message.id)})"
    )

    message
    |> Helpers.get_admin_topic()
    |> ChatApiWeb.Endpoint.broadcast!("shout", Helpers.format(message))

    message
  end

  @spec notify(Message.t(), atom(), keyword()) :: Message.t()
  def notify(message, type, opts \\ [])

  def notify(%Message{body: _, conversation_id: _} = message, :slack, opts) do
    Logger.info("Sending message notification: :slack (message #{inspect(message.id)})")

    case opts do
      # TODO: deprecate this option
      [metadata: %{"send_to_reply_channel" => false}] ->
        nil

      [send_to_reply_channel: false] ->
        nil

      [async: false] ->
        ChatApi.Slack.Notification.notify_primary_channel(message)

      _ ->
        Task.start(fn ->
          ChatApi.Slack.Notification.notify_primary_channel(message)
        end)
    end

    message
  end

  def notify(%Message{private: false} = message, :sms, _opts) do
    Logger.info("Sending message notification: :sms")

    Task.start(fn ->
      ChatApi.Twilio.Notification.notify_sms(message)
    end)

    message
  end

  def notify(
        %Message{metadata: %{"disable_webhook_events" => true}} = message,
        :webhooks,
        _opts
      ),
      do: message

  def notify(%Message{account_id: account_id} = message, :webhooks, _opts) do
    Logger.info("Sending message notification: :webhooks (message #{inspect(message.id)})")
    # TODO: how should we handle errors/retry logic?
    Task.start(fn ->
      event = %{
        "event" => "message:created",
        "payload" => Helpers.format(message)
      }

      EventSubscriptions.notify_event_subscriptions(account_id, event)

      # NB: We treat custom lambdas as webhook event handlers for customer messages
      case Helpers.get_message_type(message) do
        :customer -> Lambdas.notify_active_lambdas(account_id, event)
        _ -> nil
      end
    end)

    message
  end

  def notify(%Message{id: message_id} = message, :push, _opts) do
    Logger.info("Sending message notification: :push (message #{inspect(message.id)})")

    %{message_id: message_id}
    |> ChatApi.Workers.SendPushNotifications.new()
    |> Oban.insert()

    message
  end

  # TODO: make this a paid feature?
  def notify(%Message{customer: %Customer{}, private: false} = message, :new_message_email, opts) do
    Logger.info(
      "Sending message notification: :new_message_email (message #{inspect(message.id)})"
    )

    case opts do
      [async: false] ->
        ChatApi.Emails.send_new_message_alerts(message)

      _ ->
        # TODO: how should we handle errors/retry logic?
        Task.start(fn ->
          ChatApi.Emails.send_new_message_alerts(message)
        end)
    end

    message
  end

  def notify(%Message{} = message, :new_message_email, _opts), do: message

  def notify(%Message{} = message, :mattermost, opts) do
    Logger.info("Sending message notification: :mattermost (message #{inspect(message.id)})")

    case opts do
      [async: false] ->
        ChatApi.Mattermost.Notification.notify_primary_channel(message)

      _ ->
        Task.start(fn ->
          ChatApi.Mattermost.Notification.notify_primary_channel(message)
        end)
    end

    message
  end

  def notify(%Message{private: false} = message, :conversation_reply_email, _opts) do
    Logger.info(
      "Sending message notification: :conversation_reply_email (message #{inspect(message.id)})"
    )

    # 20 minutes (TODO: make this configurable?)
    schedule_in = 20 * 60
    formatted = Helpers.format(message)

    # TODO: not sure the best way to handle this, but basically we want to only
    # enqueue the latest message to trigger an email if it remains unseen for 2 mins
    ChatApi.Workers.SendConversationReplyEmail.cancel_pending_jobs(formatted)

    %{message: formatted}
    |> ChatApi.Workers.SendConversationReplyEmail.new(schedule_in: schedule_in)
    |> Oban.insert()

    message
  end

  def notify(
        %Message{
          id: message_id,
          account_id: account_id,
          conversation_id: conversation_id,
          user_id: user_id
        } = message,
        :mentions,
        _opts
      ) do
    Logger.info("Sending message notification: :mentions (message #{inspect(message.id)})")

    account_id
    |> ChatApi.Mentions.list_mentions(%{
      message_id: message_id,
      conversation_id: conversation_id,
      seen_at: nil
    })
    |> Stream.filter(& &1.user.has_valid_email)
    # Avoid sending notifications if users @mention themselves?
    |> Stream.reject(&(&1.user_id == user_id))
    |> Enum.each(fn mention ->
      %{
        message: Helpers.format(message),
        user: ChatApiWeb.UserView.render("user.json", user: mention.user)
      }
      |> ChatApi.Workers.SendMentionNotification.new()
      |> Oban.insert()
    end)

    message
  end

  def notify(%Message{private: false} = message, :gmail, _opts) do
    Logger.info("Sending message notification: :gmail (message #{inspect(message.id)})")

    %{message: Helpers.format(message)}
    |> ChatApi.Workers.SendGmailNotification.new()
    |> Oban.insert()

    message
  end

  def notify(%Message{private: false} = message, :slack_company_channel, _opts) do
    Logger.info(
      "Sending message notification: :slack_company_channel (message #{inspect(message.id)})"
    )

    Task.start(fn ->
      ChatApi.Slack.Notification.notify_company_channel(message)
    end)

    message
  end

  # TODO: come up with a better name... it's not super clear what `slack_support_channel` means!
  def notify(%Message{private: false} = message, :slack_support_channel, _opts) do
    Logger.info(
      "Sending message notification: :slack_support_channel (message #{inspect(message.id)})"
    )

    Task.start(fn ->
      ChatApi.Slack.Notification.notify_support_channel(message)
    end)

    message
  end

  def notify(
        %Message{
          private: false,
          id: message_id,
          user: %User{},
          conversation: %Conversation{source: "email"}
        } = message,
        :ses,
        _opts
      ) do
    Logger.info("Sending message notification: :ses (message #{inspect(message.id)})")

    %{message_id: message_id}
    |> ChatApi.Workers.SendSesReplyEmail.new()
    |> Oban.insert()

    message
  end

  def notify(%Message{} = message, :ses, _opts), do: message

  def notify(%Message{private: true} = message, type, _opts) do
    Logger.debug(
      "Skipping notification type #{inspect(type)} for private message #{inspect(message)}"
    )

    message
  end

  def notify(message, type, _opts) do
    Logger.error(
      "Unrecognized notification type #{inspect(type)} for message #{inspect(message)}"
    )

    message
  end
end
