defmodule ChatApi.Workers.SendPushNotifications do
  @moduledoc false

  use Oban.Worker, queue: :mailers

  import Ecto.Query, warn: false

  require Logger

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{
        args: %{
          "message" => %{
            "account_id" => account_id,
            "user_id" => user_id,
            "body" => body
          }
        }
      }) do
    account_id
    |> ChatApi.Users.list_users_for_push_notification(user_id)
    |> IO.inspect(label: "Users to send push notifications")
    |> Enum.map(fn user ->
      Logger.info("Sending push notification to user: #{inspect(user)}")
      # Send it to Expo
      {:ok, response} =
        ExponentServerSdk.PushNotification.push(%{
          to: user.settings.expo_push_token,
          title: "New message",
          body: body,
          # TODO: how should we handle this?
          badge:
            ChatApi.Conversations.count_conversations_where(account_id, %{
              "status" => "open",
              "read" => false
            })
        })

      response
    end)
    |> IO.inspect(label: "Expo push results")

    :ok
  end
end
