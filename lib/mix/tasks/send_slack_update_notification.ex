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
  $ mix send_slack_update_notification debug
  ```

  On Heroku:
  ```
  $ heroku run "POOL_SIZE=2 mix send_slack_update_notification"
  $ heroku run "POOL_SIZE=2 mix send_slack_update_notification debug"
  ```

  """

  @spec run([binary()]) :: list()
  def run(args) do
    Application.ensure_all_started(:chat_api)

    is_debug_mode =
      case args do
        ["debug"] -> true
        ["DEBUG"] -> true
        _ -> false
      end

    SlackAuthorizations.list_slack_authorizations(%{type: "reply"})
    |> Enum.filter(&should_notify_channel?/1)
    |> Enum.map(fn auth -> notify_papercups_app_required(auth, debug: is_debug_mode) end)
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

  @spec notify_papercups_app_required(SlackAuthorization.t(), keyword()) :: any()
  def notify_papercups_app_required(authorization, opts \\ [])

  def notify_papercups_app_required(%SlackAuthorization{} = authorization, debug: true) do
    message = """
    Would have send message:

    #{inspect(slack_notification_message())}

    To Slack channel:

    #{inspect(Map.take(authorization, [:channel, :team_name, :webhook_url]))}
    """

    Logger.info(message)
  end

  def notify_papercups_app_required(
        %SlackAuthorization{
          webhook_url: webhook_url
        },
        _opts
      ) do
    message = slack_notification_message()
    Logger.info(message)
    Slack.Notification.log(message, webhook_url)
  end

  def notify_papercups_app_required(_authorization, _opts), do: nil

  @spec slack_notification_message() :: String.t()
  def slack_notification_message() do
    """
    Hi there! :wave: This is an automated message from the Papercups team.

    We recently added some enhancements to our Slack integration that allow you to resolve, reopen, and view your conversations' status directly from Slack. :rocket: In order to do this, you'll need to add the *Papercups app* to this channel.

    You can do this by typing `/app` in the message box in this channel, clicking on "*Add apps to this channel*", and selecting the *Papercups* app.

    (If that doesn't work, try following these instructions: https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)

    If you're still having trouble, feel free to email us at founders@papercups.io. We're happy to help!
    """
  end
end
