defmodule ChatApi.Messages.Notification do
  @moduledoc """
  Notification handlers for messages
  """

  alias ChatApi.EventSubscriptions
  alias ChatApi.Messages.{Helpers, Message}

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

  def notify(
        %Message{body: _body, conversation_id: _conversation_id} = message,
        :slack,
        opts
      ) do
    Logger.info("Sending message notification: :slack (message #{inspect(message.id)})")

    case opts do
      [metadata: %{"send_to_reply_channel" => false}] ->
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

  def notify(%Message{account_id: account_id} = message, :webhooks, _opts) do
    Logger.info("Sending message notification: :webhooks (message #{inspect(message.id)})")
    # TODO: how should we handle errors/retry logic?
    Task.start(fn ->
      EventSubscriptions.notify_event_subscriptions(account_id, %{
        "event" => "message:created",
        "payload" => Helpers.format(message)
      })
    end)

    message
  end

  def notify(%Message{} = message, :new_message_email, _opts) do
    Logger.info(
      "Sending message notification: :new_message_email (message #{inspect(message.id)})"
    )

    # TODO: how should we handle errors/retry logic?
    Task.start(fn ->
      ChatApi.Emails.send_new_message_alerts(message)
    end)

    message
  end

  def notify(%Message{} = message, :mattermost, _opts) do
    Logger.info("Sending message notification: :mattermost (message #{inspect(message.id)})")

    Task.start(fn ->
      ChatApi.Mattermost.Notification.notify_primary_channel(message)
    end)

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
