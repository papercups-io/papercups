defmodule ChatApi.Workers.SendPushNotifications do
  @moduledoc false

  use Oban.Worker, queue: :mailers
  import Ecto.Query, warn: false
  require Logger

  alias ChatApi.{Conversations, Messages, Users, Slack}
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: args}) do
    case args do
      %{"message_id" => message_id} ->
        message_id
        |> Messages.get_message!()
        |> send()

      %{"account_id" => account_id} ->
        update_badge_count(account_id)

      _ ->
        Logger.error(
          "Unexpected args for ChatApi.Workers.SendPushNotifications: #{inspect(args)}"
        )

        nil
    end

    :ok
  end

  @spec send(Message.t()) :: list()
  def send(%Message{account_id: account_id, user_id: excluded_user_id, body: body} = message) do
    account_id
    # We exclude the user_id of the sender so they don't receive a notification for their own message
    |> Users.list_users_for_push_notification(excluded_user_id)
    |> Enum.map(fn user ->
      Logger.info("Sending push notification to user: #{inspect(user.email)}")
      # Send it to Expo
      {:ok, response} =
        ExponentServerSdk.PushNotification.push(%{
          to: user.settings.expo_push_token,
          title: format_notification_title(message),
          body: body,
          # TODO: how should we handle this?
          badge:
            Conversations.count_conversations_where(account_id, %{
              "status" => "open",
              "read" => false
            })
        })

      response
    end)
  end

  @spec update_badge_count(binary()) :: list()
  def update_badge_count(account_id) do
    account_id
    |> Users.list_users_for_push_notification()
    |> Enum.map(fn user ->
      count =
        Conversations.count_conversations_where(account_id, %{
          "status" => "open",
          "read" => false
        })

      Logger.info("Updating badge count to #{inspect(count)} for user: #{inspect(user.email)}")
      # Send it to Expo
      {:ok, response} =
        ExponentServerSdk.PushNotification.push(%{
          to: user.settings.expo_push_token,
          # TODO: how should we handle this?
          badge: count
        })

      response
    end)
  end

  @spec format_notification_title(Message.t()) :: binary()
  def format_notification_title(%Message{user: %User{} = user}),
    do: Slack.Notification.format_user_name(user)

  def format_notification_title(%Message{customer: %Customer{} = customer}),
    do: Slack.Notification.format_customer_name(customer)

  def format_notification_title(_), do: "Unknown User"
end
