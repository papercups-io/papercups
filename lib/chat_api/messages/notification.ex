defmodule ChatApi.Messages.Notification do
  @moduledoc """
  Notification handlers for messages
  """

  alias ChatApi.EventSubscriptions
  alias ChatApi.Messages.{Helpers, Message}

  require Logger

  @spec send_webhook_notifications(binary(), map()) :: [Tesla.Env.result()]
  def send_webhook_notifications(account_id, payload) do
    EventSubscriptions.notify_event_subscriptions(account_id, %{
      "event" => "message:created",
      "payload" => payload
    })
  end

  @spec broadcast_to_customer!(Message.t()) :: Message.t()
  def broadcast_to_customer!(%Message{} = message) do
    message
    |> Helpers.get_conversation_topic()
    |> ChatApiWeb.Endpoint.broadcast!("shout", Helpers.format(message))

    message
  end

  @spec broadcast_to_admin!(Message.t()) :: Message.t()
  def broadcast_to_admin!(%Message{} = message) do
    message
    |> Helpers.get_admin_topic()
    |> ChatApiWeb.Endpoint.broadcast!("shout", Helpers.format(message))

    message
  end

  @spec notify(Message.t(), atom()) :: Message.t()
  def notify(
        %Message{body: _body, conversation_id: _conversation_id} = message,
        :slack
      ) do
    Logger.info("Sending notification: :slack")

    Task.start(fn ->
      ChatApi.Slack.Notification.notify_primary_channel(message)
    end)

    message
  end

  def notify(%Message{account_id: account_id} = message, :webhooks) do
    Logger.info("Sending notification: :webhooks")
    # TODO: how should we handle errors/retry logic?
    Task.start(fn ->
      send_webhook_notifications(account_id, Helpers.format(message))
    end)

    message
  end

  def notify(%Message{} = message, :new_message_email) do
    Logger.info("Sending notification: :new_message_email")
    # TODO: how should we handle errors/retry logic?
    Task.start(fn ->
      ChatApi.Emails.send_new_message_alerts(message)
    end)

    message
  end

  def notify(%Message{} = message, :conversation_reply_email) do
    Logger.info("Sending notification: :conversation_reply_email")
    # 2 minutes (TODO: make this configurable?)
    schedule_in = 2 * 60
    formatted = Helpers.format(message)

    # TODO: not sure the best way to handle this, but basically we want to only
    # enqueue the latest message to trigger an email if it remains unseen for 2 mins
    ChatApi.Workers.SendConversationReplyEmail.cancel_pending_jobs(formatted)

    %{message: formatted}
    |> ChatApi.Workers.SendConversationReplyEmail.new(schedule_in: schedule_in)
    |> Oban.insert()

    message
  end

  def notify(%Message{} = message, :slack_company_channel) do
    Logger.info("Sending notification: :slack_company_channel")

    Task.start(fn ->
      ChatApi.Slack.Notification.notify_company_channel(message)
    end)

    message
  end

  # TODO: come up with a better name... it's not super clear what `slack_support_channel` means!
  def notify(%Message{} = message, :slack_support_channel) do
    Logger.info("Sending notification: :slack_support_channel")

    Task.start(fn ->
      ChatApi.Slack.Notification.notify_support_channel(message)
    end)

    message
  end

  def notify(message, type) do
    Logger.error(
      "Unrecognized notification type #{inspect(type)} for message #{inspect(message)}"
    )

    message
  end
end
