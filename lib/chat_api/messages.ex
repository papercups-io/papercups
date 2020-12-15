defmodule ChatApi.Messages do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias ChatApi.{EventSubscriptions, Repo}
  alias ChatApi.Messages.Message

  require Logger

  @spec list_messages(binary()) :: [Message.t()]
  def list_messages(account_id) do
    Message |> where(account_id: ^account_id) |> preload(:conversation) |> Repo.all()
  end

  @spec list_by_conversation(binary(), binary(), keyword()) :: [Message.t()]
  def list_by_conversation(conversation_id, account_id, limit: limit) do
    Message
    |> where(account_id: ^account_id, conversation_id: ^conversation_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload([:customer, [user: :profile]])
    |> Repo.all()
  end

  @spec count_messages_by_account(binary()) :: integer()
  def count_messages_by_account(account_id) do
    query =
      from(m in Message,
        where: m.account_id == ^account_id,
        select: count("*")
      )

    Repo.one(query)
  end

  @spec get_message!(binary()) :: Message.t()
  def get_message!(id) do
    Message |> Repo.get!(id) |> Repo.preload([:conversation, :customer, [user: :profile]])
  end

  @spec create_message(map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_and_fetch!(map()) :: Message.t() | {:error, Ecto.Changeset.t()}
  def create_and_fetch!(attrs \\ %{}) do
    case create_message(attrs) do
      {:ok, message} -> get_message!(message.id)
      error -> error
    end
  end

  @spec get_message_type(Message.t()) :: atom()
  def get_message_type(%Message{customer_id: nil}), do: :agent
  def get_message_type(%Message{user_id: nil}), do: :customer
  def get_message_type(_message), do: :unknown

  @spec send_webhook_notifications(binary(), map()) :: [Tesla.Env.result()]
  def send_webhook_notifications(account_id, payload) do
    EventSubscriptions.notify_event_subscriptions(account_id, %{
      "event" => "message:created",
      "payload" => payload
    })
  end

  @spec get_conversation_topic(Message.t()) :: binary()
  def get_conversation_topic(%{conversation_id: conversation_id} = _message),
    do: "conversation:" <> conversation_id

  @spec format(Message.t()) :: map()
  def format(%Message{} = message),
    do: ChatApiWeb.MessageView.render("expanded.json", message: message)

  @spec broadcast_to_conversation!(Message.t()) :: Message.t()
  def broadcast_to_conversation!(%Message{} = message) do
    message
    |> get_conversation_topic()
    |> ChatApiWeb.Endpoint.broadcast!("shout", format(message))

    message
  end

  @spec update_message(Message.t(), map()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_message(Message.t()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @spec change_message(Message.t(), map()) :: Ecto.Changeset.t()
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  # Notifications
  # TODO: move these into a different module???
  # TODO: move more of these to be queued up in Oban?

  @spec notify(Message.t(), atom()) :: Message.t()
  def notify(
        %Message{body: _body, conversation_id: _conversation_id} = message,
        :slack
      ) do
    Logger.info("Sending notification: :slack")
    # TODO: should we just pass in the message struct here?
    Task.start(fn ->
      ChatApi.Slack.send_conversation_message_alert_v2(message)
    end)

    message
  end

  def notify(%Message{account_id: account_id} = message, :webhooks) do
    Logger.info("Sending notification: :webhooks")
    # TODO: use Oban instead?
    Task.start(fn ->
      send_webhook_notifications(account_id, format(message))
    end)

    message
  end

  def notify(%Message{} = message, :new_message_email) do
    Logger.info("Sending notification: :new_message_email")
    # TODO: use Oban instead?
    Task.start(fn ->
      # TODO: update params to just accept a full `message` object/struct,
      # so that we can include some info about the customer in the email as well
      ChatApi.Emails.send_new_message_alerts(message)
    end)

    message
  end

  def notify(%Message{} = message, :conversation_reply_email) do
    Logger.info("Sending notification: :conversation_reply_email")
    # 2 minutes (TODO: make this configurable?)
    schedule_in = 2 * 60
    formatted = format(message)

    # TODO: not sure the best way to handle this, but basically we want to only
    # enqueue the latest message to trigger an email if it remains unseen for 2 mins
    ChatApi.Workers.SendConversationReplyEmail.cancel_pending_jobs(formatted)

    %{message: formatted}
    |> ChatApi.Workers.SendConversationReplyEmail.new(schedule_in: schedule_in)
    |> Oban.insert()

    message
  end

  # TODO: come up with a better name... it's not super clear what `other_slack_threads` means!
  def notify(%Message{} = message, :other_slack_threads) do
    Logger.info("Sending notification: :other_slack_threads")
    # TODO: should we just pass in the message struct here?
    Task.start(fn ->
      ChatApi.Slack.notify_auxiliary_threads(message)
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
