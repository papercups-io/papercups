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
  def notify_primary_channel(
        %Message{
          conversation_id: conversation_id,
          body: text,
          account_id: account_id
        } = message
      ) do
    # TODO: handle getting all these fields in a separate function?
    with %{customer: customer} <-
           Conversations.get_conversation_with!(conversation_id, :customer),
         %{access_token: access_token, channel: channel, channel_id: channel_id} <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"}) do
      thread = SlackConversationThreads.get_thread_by_conversation_id(conversation_id, channel_id)

      # TODO: use a struct here?
      %{
        customer: customer,
        text: text,
        conversation_id: conversation_id,
        type: Slack.Helpers.get_message_type(message),
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
  end

  @spec notify_support_channel(ChatApi.Messages.Message.t()) :: :ok
  def notify_support_channel(%Message{account_id: account_id} = message) do
    case SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}) do
      %{access_token: access_token, channel_id: channel_id} ->
        notify_slack_channel(access_token, channel_id, message)

      _ ->
        nil
    end
  end

  @spec notify_company_channel(ChatApi.Messages.Message.t()) :: :ok
  def notify_company_channel(
        %Message{account_id: account_id, conversation_id: conversation_id} = message
      ) do
    with %{access_token: access_token} <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}),
         %{customer: %{company: %{slack_channel_id: channel_id}}} <-
           Conversations.get_conversation_with(conversation_id, customer: :company) do
      notify_slack_channel(access_token, channel_id, message)
    end
  end

  @spec notify_slack_channel(binary(), ChatApi.Messages.Message.t()) :: :ok
  def notify_slack_channel(channel_id, %Message{account_id: account_id} = message) do
    case SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}) do
      %{access_token: access_token} ->
        notify_slack_channel(access_token, channel_id, message)

      _ ->
        nil
    end
  end

  @spec notify_slack_channel(binary(), binary(), ChatApi.Messages.Message.t()) :: :ok
  def notify_slack_channel(access_token, channel_id, %Message{
        conversation_id: conversation_id,
        body: text
      }) do
    conversation_id
    |> SlackConversationThreads.get_threads_by_conversation_id()
    |> Stream.filter(fn thread -> thread.slack_channel == channel_id end)
    |> Enum.each(fn thread ->
      message = %{
        "text" => text,
        "channel" => thread.slack_channel,
        "thread_ts" => thread.slack_thread_ts
      }

      Slack.Client.send_message(message, access_token)
    end)
  end
end
