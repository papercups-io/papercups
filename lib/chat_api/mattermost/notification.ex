defmodule ChatApi.Mattermost.Notification do
  @moduledoc """
  A module to handle sending Mattermost notifications.
  """

  require Logger

  alias ChatApi.{Mattermost, Slack}
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  alias ChatApi.Mattermost.{
    MattermostAuthorization,
    MattermostConversationThread
  }

  @spec notify_primary_channel(Message.t()) :: any()
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

  @spec notify_existing_thread(
          Message.t(),
          MattermostConversationThread.t(),
          MattermostAuthorization.t()
        ) :: any()
  def notify_existing_thread(message, thread, authorization) do
    Mattermost.Client.send_message(
      %{
        channel_id: authorization.channel_id,
        root_id: thread.mattermost_post_root_id,
        # TODO: modify message accordingly?
        message: format_mattermost_message(message)
      },
      authorization
    )
  end

  @spec notify_and_create_new_thread(Message.t(), MattermostAuthorization.t()) :: any()
  def notify_and_create_new_thread(message, authorization) do
    with {:ok, %{body: %{"id" => post_id, "channel_id" => channel_id}}} <-
           Mattermost.Client.send_message(
             %{
               channel_id: authorization.channel_id,
               # TODO: modify message accordingly?
               message: format_mattermost_message(message)
             },
             authorization
           ) do
      Mattermost.create_mattermost_conversation_thread(%{
        mattermost_channel_id: channel_id,
        mattermost_post_root_id: post_id,
        account_id: message.account_id,
        conversation_id: message.conversation_id
      })
    end
  end

  @spec format_mattermost_message(Message.t()) :: binary()
  defp format_mattermost_message(%Message{} = message) do
    message
    |> format_message_body()
    |> prepend_sender_prefix(message)
  end

  # Same logic as our Slack integration
  @spec format_message_body(Message.t()) :: binary()
  def format_message_body(%Message{body: nil}), do: ""
  def format_message_body(%Message{private: true, type: "note", body: nil}), do: "\\\\ _Note_"
  def format_message_body(%Message{private: true, type: "note", body: body}), do: "\\\\ _#{body}_"
  def format_message_body(%Message{body: body}), do: body

  # Similar to our Slack integration logic, but the emoji names are slightly different
  @spec prepend_sender_prefix(binary(), Message.t()) :: binary()
  def prepend_sender_prefix(text, %Message{} = message) do
    case message do
      %Message{user: %User{} = user} ->
        "*:woman_technologist: #{Slack.Notification.format_user_name(user)}*: #{text}"

      %Message{customer: %Customer{} = customer} ->
        "*:wave: #{Slack.Notification.format_customer_name(customer)}*: #{text}"

      %Message{customer_id: nil, user_id: user_id} when not is_nil(user_id) ->
        "*:woman_technologist: Agent*: #{text}"

      _ ->
        Logger.error("Unrecognized message format: #{inspect(message)}")

        text
    end
  end
end
