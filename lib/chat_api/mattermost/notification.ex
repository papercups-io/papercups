defmodule ChatApi.Mattermost.Notification do
  @moduledoc """
  A module to handle sending Mattermost notifications.
  """

  require Logger

  alias ChatApi.Mattermost
  alias ChatApi.Messages.Message

  @spec notify_primary_channel(Message.t()) :: Tesla.Env.result() | nil | :ok
  def notify_primary_channel(
        %Message{
          id: _message_id,
          conversation_id: conversation_id,
          body: _body,
          account_id: account_id
        } = message
      ) do
    with %{access_token: _access_token, channel_id: _channel_id} = authorization <-
           Mattermost.get_authorization_by_account(account_id) do
      case Mattermost.get_thread_by_conversation_id(conversation_id) do
        %{mattermost_post_root_id: _root_id} = thread ->
          notify_existing_thread(message, thread, authorization)

        _ ->
          notify_and_create_new_thread(message, authorization)
      end
    end
  end

  def notify_existing_thread(message, thread, authorization) do
    Mattermost.Client.send_message(
      %{
        channel_id: authorization.channel_id,
        root_id: thread.mattermost_post_root_id,
        # TODO: modify message accordingly?
        message: message.body
      },
      authorization.access_token
    )
  end

  def notify_and_create_new_thread(message, authorization) do
    with {:ok, %{body: %{"id" => post_id, "channel_id" => channel_id}}} <-
           Mattermost.Client.send_message(
             %{
               channel_id: authorization.channel_id,
               # TODO: modify message accordingly?
               message: message.body
             },
             authorization.access_token
           ) do
      Mattermost.create_mattermost_conversation_thread(%{
        mattermost_channel_id: channel_id,
        mattermost_post_root_id: post_id,
        account_id: message.account_id,
        conversation_id: message.conversation_id
      })
    end
  end
end
