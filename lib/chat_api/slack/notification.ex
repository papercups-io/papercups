defmodule ChatApi.Slack.Notification do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  require Logger

  alias ChatApi.{
    Conversations,
    Customers.Customer,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads,
    Messages.Message
  }

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Users.{User, UserProfile}
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.SlackConversationThreads.SlackConversationThread

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
          id: message_id,
          conversation_id: conversation_id,
          body: _body,
          account_id: account_id
        } = message
      ) do
    Logger.info("Calling ChatApi.Slack.Notification.notify_primary_channel")
    # TODO: handle getting all these fields in a separate function?
    with %Conversation{} = conversation <-
           Conversations.get_conversation_with!(conversation_id, :customer),
         %SlackAuthorization{channel_id: channel_id} = authorization <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "reply"}),
         is_first_message <-
           Conversations.is_first_message?(conversation_id, message_id),
         thread <-
           SlackConversationThreads.get_thread_by_conversation_id(conversation_id, channel_id),
         :ok <- validate_send_to_primary_channel(thread, is_first_message: is_first_message) do
      case validate_send_to_primary_channel(thread, is_first_message: is_first_message) do
        :ok ->
          send_to_primary_channel(%{
            conversation: conversation,
            message: message,
            authorization: authorization,
            thread: thread
          })

        {:error, :conversation_exists_without_thread} ->
          sync_conversation_messages_to_primary_channel(%{
            conversation: conversation,
            authorization: authorization,
            thread: thread
          })

        error ->
          Logger.error("Unable to send Slack message: #{inspect(error)}")
      end
    else
      error ->
        Logger.info("Skipped sending Slack message: #{inspect(error)}")
    end
  end

  @spec send_to_primary_channel(%{
          :authorization => SlackAuthorization.t(),
          :conversation => Conversation.t(),
          :message => Message.t(),
          :thread => nil | SlackConversationThread.t()
        }) :: nil | :ok | {:error, any} | {:ok, nil | Tesla.Env.t()}
  def send_to_primary_channel(%{
        conversation: %Conversation{id: conversation_id, customer: customer} = conversation,
        message: message,
        authorization:
          %SlackAuthorization{access_token: access_token, channel: channel} = authorization,
        thread: thread
      }) do
    %{
      conversation: conversation,
      message: message,
      authorization: authorization,
      thread: thread
    }
    |> Slack.Helpers.get_message_text()
    |> Slack.Helpers.get_message_payload(%{
      channel: channel,
      conversation: conversation,
      customer: customer,
      thread: thread,
      message: message
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

  @spec sync_conversation_messages_to_primary_channel(%{
          :authorization => SlackAuthorization.t(),
          :conversation => Conversation.t(),
          :thread => nil | SlackConversationThread.t()
        }) :: :ok
  def sync_conversation_messages_to_primary_channel(%{
        conversation: %Conversation{id: conversation_id} = conversation,
        authorization: authorization,
        thread: thread
      }) do
    conversation_id
    |> Conversations.get_conversation!()
    |> Map.get(:messages, [])
    |> Enum.sort_by(&{&1.inserted_at, &1.sent_at}, NaiveDateTime)
    |> Enum.each(fn message ->
      send_to_primary_channel(%{
        conversation: conversation,
        message: message,
        authorization: authorization,
        thread: thread
      })

      # TODO: how should we handle this?
      Process.sleep(200)
    end)
  end

  @spec notify_support_channel(Message.t()) :: :ok
  def notify_support_channel(%Message{account_id: account_id} = message) do
    case SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}) do
      %{access_token: access_token, channel_id: channel_id} ->
        notify_slack_channel(access_token, channel_id, message)

      _ ->
        nil
    end
  end

  @spec notify_company_channel(Message.t()) :: :ok
  def notify_company_channel(
        %Message{account_id: account_id, conversation_id: conversation_id} = message
      ) do
    with %{access_token: access_token, channel_id: primary_channel_id} <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}),
         %{customer: %{company: %{slack_channel_id: company_channel_id}}} <-
           Conversations.get_conversation_with(conversation_id, customer: :company),
         # If a company has been assigned the channel that matches the primary channel,
         # we skip sending the notification here to avoid double messages.
         # In the future we will probably want to deprecated the "primary" support channel,
         # in which case this check will become irrelevant.
         false <- primary_channel_id == company_channel_id do
      notify_slack_channel(access_token, company_channel_id, message)
    end
  end

  @spec notify_slack_channel(binary(), Message.t()) :: :ok
  def notify_slack_channel(channel_id, %Message{account_id: account_id} = message) do
    case SlackAuthorizations.get_authorization_by_account(account_id, %{type: "support"}) do
      %{access_token: access_token} ->
        notify_slack_channel(access_token, channel_id, message)

      _ ->
        nil
    end
  end

  @spec notify_slack_channel(binary(), binary(), Message.t()) :: :ok
  def notify_slack_channel(
        access_token,
        channel_id,
        %Message{conversation_id: conversation_id, user: user} = message
      ) do
    conversation_id
    |> SlackConversationThreads.get_threads_by_conversation_id()
    |> Stream.filter(fn thread -> thread.slack_channel == channel_id end)
    |> Enum.each(fn thread ->
      message = %{
        "text" => format_slack_message_text(message),
        "channel" => thread.slack_channel,
        "thread_ts" => thread.slack_thread_ts,
        "username" => format_user_name(user),
        "icon_url" => slack_icon_url(user)
      }

      Slack.Client.send_message(message, access_token)
    end)
  end

  # If `is_first_message: true` or a valid Slack thread exists already, return :ok.
  # Otherwise, return :error (i.e. we don't want to start a new thread with a non-initial message)
  @spec validate_send_to_primary_channel(SlackConversationThread.t() | nil, [
          {:is_first_message, boolean}
        ]) :: :ok | {:error, atom()}
  def validate_send_to_primary_channel(nil, is_first_message: false),
    do: {:error, :conversation_exists_without_thread}

  def validate_send_to_primary_channel(_thread, is_first_message: true), do: :ok
  def validate_send_to_primary_channel(%SlackConversationThread{}, _opts), do: :ok
  def validate_send_to_primary_channel(_thread, _opts), do: {:error, :unexpected_thread_state}

  # TODO: maybe these methods below belong in the Slack.Helpers module?

  @spec format_slack_message_text(Message.t()) :: String.t()
  def format_slack_message_text(%Message{} = message) do
    case message do
      %{customer: %Customer{} = customer} when not is_nil(customer) ->
        # We only want to prepend sender info for customer messages
        message
        |> Slack.Helpers.format_message_body()
        |> Slack.Helpers.prepend_sender_prefix(message)
        |> Slack.Helpers.append_attachments_text(message)

      _ ->
        message
        |> Slack.Helpers.format_message_body()
        |> Slack.Helpers.append_attachments_text(message)
    end
  end

  @spec format_user_name(User.t() | nil) :: String.t()
  def format_user_name(%User{} = user) do
    case user do
      %{profile: %UserProfile{display_name: display_name}}
      when not is_nil(display_name) ->
        display_name

      %{profile: %UserProfile{full_name: full_name}}
      when not is_nil(full_name) ->
        full_name

      %{email: email} ->
        email

      _ ->
        default_app_name()
    end
  end

  @spec format_customer_name(Customer.t()) :: binary()
  def format_customer_name(%Customer{email: email, name: name}) do
    case [name, email] do
      [nil, nil] -> "Anonymous User"
      [x, nil] -> x
      [nil, y] -> y
      [x, y] -> "#{x} (#{y})"
    end
  end

  @spec slack_icon_url(User.t() | nil) :: String.t()
  def slack_icon_url(%User{} = user) do
    case user do
      %{profile: %UserProfile{profile_photo_url: profile_photo_url}}
      when not is_nil(profile_photo_url) ->
        profile_photo_url

      _ ->
        default_app_icon_url()
    end
  end

  @papercups_app_name "Papercups"
  @papercups_icon_url "https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2021-01-05/1626939067681_3e27968eb3657d7167e5_132.png"

  @spec default_app_name() :: String.t()
  defp default_app_name() do
    System.get_env("PAPERCUPS_APP_NAME", @papercups_app_name)
  end

  @spec default_app_icon_url() :: String.t()
  defp default_app_icon_url() do
    System.get_env("PAPERCUPS_APP_ICON_URL", @papercups_icon_url)
  end
end
