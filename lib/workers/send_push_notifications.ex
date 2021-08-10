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
  def perform(%Oban.Job{args: %{"message_id" => message_id}}) do
    message_id
    |> Messages.get_message!()
    |> send()

    :ok
  end

  @spec send(Message.t()) :: any()
  def send(%Message{account_id: account_id, user_id: user_id, body: body} = message) do
    account_id
    |> Users.list_users_for_push_notification(user_id)
    |> IO.inspect(label: "Users to send push notifications")
    |> Enum.map(fn user ->
      Logger.info("Sending push notification to user: #{inspect(user)}")
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
    |> IO.inspect(label: "Expo push results")
  end

  @spec format_notification_title(Message.t()) :: binary()
  def format_notification_title(%Message{user: %User{} = user}),
    do: Slack.Notification.format_user_name(user)

  def format_notification_title(%Message{customer: %Customer{} = customer}),
    do: Slack.Notification.format_customer_name(customer)

  def format_notification_title(_), do: "Unknown User"
end
