defmodule ChatApi.Workers.SendAccountConversationReminders do
  @moduledoc false

  use Oban.Worker, queue: :default

  alias ChatApi.{Accounts, Conversations, Messages}
  alias ChatApi.Accounts.{Account, Settings}
  alias ChatApi.Conversations.Conversation

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    Logger.info("Triggering conversation reminders for account #{account_id}")

    account_id
    |> Accounts.get_account!()
    |> run()

    :ok
  end

  # Default hours for testing
  @three_days_ago 72

  def run(
        %Account{
          id: account_id,
          settings: %Settings{conversation_reminders_enabled: true} = settings
        } = _account
      ) do
    hours =
      case Map.get(settings, :conversation_reminder_hours_interval) do
        num when is_integer(num) -> num
        _ -> @three_days_ago
      end

    account_id
    |> Conversations.list_forgotten_conversations(hours)
    # Just handle 10 at a time for now to avoid spamming reminders
    |> Enum.slice(0..9)
    |> Enum.map(&send_reminder_message/1)
  end

  def run(_account), do: nil

  def send_reminder_message(
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          assignee_id: assignee_id
        } = _conversation
      ) do
    user_id =
      case assignee_id do
        nil -> account_id |> Accounts.get_primary_user() |> Map.get(:id)
        id -> id
      end

    %{
      body:
        "This is an automated reminder to follow up on this conversation :bell:" <>
          "\n\n" <> "(Click [here](/account/overview) to configure reminders for your account)",
      type: "bot",
      private: true,
      conversation_id: conversation_id,
      account_id: account_id,
      user_id: user_id,
      sent_at: DateTime.utc_now(),
      metadata: %{is_reminder: true}
    }
    |> Messages.create_and_fetch!()
    |> Messages.Notification.broadcast_to_admin!()
    |> Messages.Notification.notify(:slack)
    |> Messages.Notification.notify(:mattermost)
    |> Messages.Notification.notify(:webhooks)
    |> Messages.Helpers.handle_post_creation_conversation_updates()
  end
end
