defmodule ChatApi.Messages do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias ChatApi.{EventSubscriptions, Repo}
  alias ChatApi.Messages.Message

  require Logger

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages(account_id)
      [%Message{}, ...]

  """
  def list_messages(account_id) do
    Message |> where(account_id: ^account_id) |> preload(:conversation) |> Repo.all()
  end

  def list_by_conversation(conversation_id, account_id, limit: limit) do
    Message
    |> where(account_id: ^account_id, conversation_id: ^conversation_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload([:customer, [user: :profile]])
    |> Repo.all()
  end

  def count_messages_by_account(account_id) do
    query =
      from(m in Message,
        where: m.account_id == ^account_id,
        select: count("*")
      )

    Repo.one(query)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id) do
    Message |> Repo.get!(id) |> Repo.preload([:conversation, :customer, [user: :profile]])
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def create_and_fetch!(attrs \\ %{}) do
    case create_message(attrs) do
      {:ok, message} -> get_message!(message.id)
      error -> error
    end
  end

  def get_message_type(%Message{customer_id: nil}), do: :agent
  def get_message_type(%Message{user_id: nil}), do: :customer
  def get_message_type(_message), do: :unknown

  def send_webhook_notifications(account_id, payload) do
    EventSubscriptions.notify_event_subscriptions(account_id, %{
      "event" => "message:created",
      "payload" => payload
    })
  end

  def get_conversation_topic(%{conversation_id: conversation_id} = _message),
    do: "conversation:" <> conversation_id

  def format(%Message{} = message),
    do: ChatApiWeb.MessageView.render("expanded.json", message: message)

  def broadcast_to_conversation!(%Message{} = message) do
    message
    |> get_conversation_topic()
    |> ChatApiWeb.Endpoint.broadcast!("shout", format(message))

    message
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  # Notifications
  # TODO: move more of these to be queued up in Oban

  @spec notify(Message.t(), atom()) :: Message.t()
  def notify(
        %Message{body: body, conversation_id: conversation_id} = message,
        :slack
      ) do
    Logger.info("Sending notification: :slack")
    # TODO: should we just pass in the message struct here?
    Task.start(fn ->
      ChatApi.Slack.send_conversation_message_alert(conversation_id, body,
        type: get_message_type(message)
      )
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

  def notify(
        %Message{
          body: body,
          account_id: account_id,
          conversation_id: conversation_id
        } = message,
        :new_message_email
      ) do
    Logger.info("Sending notification: :new_message_email")
    # TODO: use Oban instead?
    Task.start(fn ->
      ChatApi.Emails.send_new_message_alerts(body, account_id, conversation_id)
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

  def notify(message, type) do
    Logger.error(
      "Unrecognized notification type #{inspect(type)} for message #{inspect(message)}"
    )

    message
  end
end
