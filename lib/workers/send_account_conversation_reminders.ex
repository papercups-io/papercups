defmodule ChatApi.Workers.SendAccountConversationReminders do
  @moduledoc false

  use Oban.Worker, queue: :default

  alias ChatApi.Conversations.Conversation

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    run(account_id)

    :ok
  end

  # Default hours for testing
  @three_days_ago 72

  def run(account_id) do
    account_id
    |> ChatApi.Conversations.list_forgotten_conversations(@three_days_ago)
    # Just handle 10 at a time for now to avoid spamming reminders
    |> Enum.slice(0..9)
    |> Enum.map(&send_reminder_message/1)
  end

  def send_reminder_message(
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          assignee_id: assignee_id
        } = _conversation
      ) do
    user_id =
      case assignee_id do
        nil -> account_id |> ChatApi.Accounts.get_primary_user() |> Map.get(:id)
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
    |> ChatApi.Messages.create_and_fetch!()
    |> ChatApi.Messages.Notification.broadcast_to_admin!()
    |> ChatApi.Messages.Notification.notify(:slack)
    |> ChatApi.Messages.Notification.notify(:mattermost)
    |> ChatApi.Messages.Notification.notify(:webhooks)
  end
end
