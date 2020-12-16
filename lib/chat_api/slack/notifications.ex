defmodule ChatApi.Slack.Notifications do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  require Logger

  alias ChatApi.{
    Conversations,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads,
    Messages.Message
  }

  @spec log(binary()) :: :ok | Tesla.Env.result()
  def log(message) do
    case System.get_env("PAPERCUPS_SLACK_WEBHOOK_URL") do
      "https://hooks.slack.com/services/" <> _rest = url ->
        log(message, url)

      _ ->
        Logger.info("Slack log: #{inspect(message)}")
    end
  end

  @spec log(binary(), binary()) :: Tesla.Env.result()
  def log(message, webhook_url) do
    [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"content-type", "application/json"}]}
    ]
    |> Tesla.client()
    |> Tesla.post(webhook_url, %{"text" => message})
  end

  @spec notify_primary_channel(Message.t()) :: Tesla.Env.result() | nil | :ok
  def notify_primary_channel(%Message{conversation_id: conversation_id, body: text} = message) do
    type = Slack.Helpers.get_message_type(message)
    # TODO: handle getting all these fields in a separate function?
    %{account_id: account_id, customer: customer} =
      Conversations.get_conversation_with!(conversation_id, :customer)

    auth = SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"})
    %{access_token: access_token, channel: channel, channel_id: channel_id} = auth

    # Check if a Slack thread already exists for this conversation.
    # If one exists, send followup messages as replies; otherwise, start a new thread
    # TODO: get ALL relevant threads, and send messages to all of them? ¯\_(ツ)_/¯
    # TODO: make it possible to override the channel_id or thread in a argument above???
    # ...we need more granular control over where thesee messages are sent!
    # TODO: actually, this method is currently only really relevant for the "main"
    # Slack channel that's authorized... we'll probably need a separate method that just:
    # forwards a message to any existing Slack thread?
    thread = SlackConversationThreads.get_thread_by_conversation_id(conversation_id, channel_id)

    # TODO: use a struct here?
    %{
      customer: customer,
      text: text,
      conversation_id: conversation_id,
      type: type,
      thread: thread
    }
    |> Slack.Helpers.get_message_text()
    |> Slack.Helpers.get_message_payload(%{
      channel: channel,
      customer: customer,
      thread: thread
    })
    |> Slack.Client.send_message(access_token)
    |> case do
      # Just pass through in test/dev mode (not sure if there's a more idiomatic way to do this)
      {:ok, nil} ->
        nil

      {:ok, response} ->
        # If no thread exists yet, start a new thread and kick off the first reply
        if is_nil(thread) do
          {:ok, thread} =
            Slack.Helpers.create_new_slack_conversation_thread(conversation_id, response)

          Slack.Client.send_message(
            %{
              "channel" => channel,
              "text" => "(Send a message here to get started!)",
              "thread_ts" => thread.slack_thread_ts
            },
            access_token
          )
        end

      error ->
        Logger.error("Unable to send Slack message: #{inspect(error)}")
    end
  end

  @spec notify_auxiliary_threads(ChatApi.Messages.Message.t()) :: :ok
  def notify_auxiliary_threads(%Message{
        conversation_id: conversation_id,
        account_id: account_id,
        body: text
      }) do
    auth = SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"})

    conversation_id
    |> SlackConversationThreads.get_threads_by_conversation_id()
    |> Stream.filter(fn thread -> thread.slack_channel == auth.channel_id end)
    |> Enum.each(fn thread ->
      # TODO: should we use Task.async/await/yield here?
      IO.inspect("!!! SENDING MESSAGE FOR THREAD !!!")
      IO.inspect(thread)

      message = %{
        "text" => text,
        "channel" => thread.slack_channel,
        "thread_ts" => thread.slack_thread_ts
      }

      IO.inspect(message)

      result = Slack.Client.send_message(message, auth.access_token)

      IO.inspect(result)
    end)
  end
end
