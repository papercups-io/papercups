defmodule ChatApi.Workers.SendAccountConversationReminders do
  @moduledoc false

  use Oban.Worker, queue: :default

  alias ChatApi.{Accounts, Conversations, Messages}
  alias ChatApi.Accounts.{Account, Settings}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"account_id" => account_id}}) do
    Logger.info("Triggering conversation reminders for account #{account_id}")

    account = Accounts.get_account!(account_id)

    # Skip sending reminders when outside working hours
    case Accounts.is_outside_working_hours?(account) do
      false ->
        run(account)

      true ->
        Logger.info(
          "Skipping conversation reminders, currently outside working hours: #{
            inspect(account.working_hours)
          }"
        )
    end

    :ok
  end

  # Default hours for testing
  @three_days_ago 72
  @default_max_reminders 3

  def run(
        %Account{
          id: account_id,
          settings: %Settings{conversation_reminders_enabled: true} = settings
        } = _account
      ) do
    hours = get_hours_interval_config(settings)
    max = get_max_reminders_config(settings)

    account_id
    |> Conversations.list_forgotten_conversations(hours)
    |> Enum.filter(fn conv -> should_send_reminder?(conv, max) end)
    # Just handle 10 at a time for now to avoid spamming reminders
    |> Enum.slice(0..9)
    |> Enum.map(fn conv -> send_reminder_message(conv, max, hours) end)
  end

  def run(_account), do: nil

  def should_send_reminder?(conversation, max \\ @default_max_reminders)

  def should_send_reminder?(%Conversation{messages: messages}, max) when is_list(messages) do
    case List.first(messages) do
      %Message{metadata: %{"is_reminder" => true, "reminder_count" => n}} ->
        n < max

      _ ->
        true
    end
  end

  def should_send_reminder?(_conversation, _max), do: false

  def send_reminder_message(
        %Conversation{
          id: conversation_id,
          account_id: account_id,
          assignee_id: assignee_id
        } = conversation,
        max,
        hours
      ) do
    user_id =
      case assignee_id do
        nil -> account_id |> Accounts.get_primary_user() |> Map.get(:id)
        id -> id
      end

    latest_message = conversation |> Map.get(:messages, []) |> List.first()
    hours_label = if hours == 1, do: "hour", else: "hours"

    metadata =
      case latest_message do
        %Message{metadata: %{"is_reminder" => true, "reminder_count" => n}} ->
          %{"is_reminder" => true, "reminder_count" => n + 1}

        # In this case, we may have forgotten to set the count...
        %Message{metadata: %{"is_reminder" => true}} ->
          %{"is_reminder" => true, "reminder_count" => 2}

        _ ->
          %{"is_reminder" => true, "reminder_count" => 1}
      end

    body =
      case metadata do
        %{"reminder_count" => n} when n == max and max > 1 ->
          "This is the last reminder to follow up on this conversation :bell: no more will be sent after this!" <>
            "\n\n" <> "(Click [here](/settings/overview) to configure reminders for your account)"

        %{"reminder_count" => n} when n < max ->
          "This is an automated reminder (#{n} of #{max}) to follow up on this conversation :bell: " <>
            "the next reminder will be sent in #{hours} #{hours_label}." <>
            "\n\n" <> "(Click [here](/settings/overview) to configure reminders for your account)"

        _ ->
          "This is an automated reminder to follow up on this conversation :bell:" <>
            "\n\n" <> "(Click [here](/settings/overview) to configure reminders for your account)"
      end

    %{
      body: body,
      type: "bot",
      private: true,
      conversation_id: conversation_id,
      account_id: account_id,
      user_id: user_id,
      sent_at: DateTime.utc_now(),
      metadata: metadata
    }
    |> Messages.create_and_fetch!()
    |> Messages.Notification.broadcast_to_admin!()
    |> Messages.Notification.notify(:slack)
    |> Messages.Notification.notify(:mattermost)
    |> Messages.Notification.notify(:webhooks)
    |> Messages.Helpers.handle_post_creation_hooks()
  end

  defp get_hours_interval_config(settings) do
    case Map.get(settings, :conversation_reminder_hours_interval) do
      num when is_integer(num) -> num
      _ -> @three_days_ago
    end
  end

  def get_max_reminders_config(settings) do
    case Map.get(settings, :max_num_conversation_reminders) do
      num when is_integer(num) -> num
      _ -> @default_max_reminders
    end
  end
end
