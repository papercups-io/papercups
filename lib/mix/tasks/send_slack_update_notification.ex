defmodule Mix.Tasks.SendSlackUpdateNotification do
  use Mix.Task

  require Logger
  import Ecto.Query, warn: false
  alias ChatApi.{Slack, SlackAuthorizations, SlackConversationThreads}
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.SlackConversationThreads.SlackConversationThread

  @shortdoc "Sends notifications to Slack for channels missing the Papercups app"

  @moduledoc """
  This task handles sending notifications to Slack for channels missing the Papercups app,
  which is required for some additional functionality (such as resolving/reopening conversations
  directly from the Slack channel).

  Example:
  ```
  $ mix send_slack_update_notification
  ```

  On Heroku:
  ```
  $ heroku run "POOL_SIZE=2 mix send_slack_update_notification"
  ```

  """

  @spec run(any()) :: list()
  def run(_args) do
    Application.ensure_all_started(:chat_api)

    SlackAuthorizations.list_slack_authorizations(%{type: "reply"})
    |> Enum.filter(&should_notify_channel?/1)
    |> Enum.map(&notify_papercups_app_required/1)
  end

  @spec should_notify_channel?(SlackAuthorization.t()) :: boolean()
  def should_notify_channel?(%SlackAuthorization{
        account_id: account_id,
        channel_id: channel_id,
        access_token: access_token
      }) do
    with %SlackConversationThread{slack_channel: channel, slack_thread_ts: ts} <-
           SlackConversationThreads.get_latest_slack_conversation_thread(%{
             "account_id" => account_id,
             "slack_channel" => channel_id
           }),
         {:ok, %{body: %{"error" => "not_in_channel", "ok" => false}}} <-
           Slack.Client.retrieve_message(channel, ts, access_token) do
      true
    else
      _ -> false
    end
  end

  def should_notify_channel?(_), do: false

  @spec notify_papercups_app_required(SlackAuthorization.t()) :: any()
  def notify_papercups_app_required(%SlackAuthorization{
        webhook_url: webhook_url
      }) do
    message = """
    Hi there! :wave: This is an automated message from the Papercups team.

    We recently added some enhancements to our Slack integration that allow you to resolve, reopen, and view your conversations' status directly from Slack. :rocket: In order to do this, you'll need to add the *Papercups app* to this channel.

    You can do this by typing `/app` in the message box in this channel, clicking on "*Add apps to this channel*", and selecting the *Papercups* app.

    (If that doesn't work, try following these instructions: https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)

    If you're still having trouble, feel free to email us at founders@papercups.io. We're happy to help!
    """

    Logger.info(message)

    Slack.Notification.log(message, webhook_url)
  end

  def notify_papercups_app_required(_), do: nil
end
