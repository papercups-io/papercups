defmodule ChatApi.Slack do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://hooks.slack.com"
  plug Tesla.Middleware.Headers, [{"content-type", "application/json"}]
  plug Tesla.Middleware.JSON

  def send(message) do
    webhook_url = System.get_env("PAPERCUPS_SLACK_WEBHOOK_URL")

    if is_nil(webhook_url) do
      raise "The SLACK_WEBHOOK_URL environment variable is required to send Slack messages"
    end

    post(webhook_url, message)
  end

  def send_conversation_message_alert(conversation_id, text) do
    # TODO: handle this in user settings, for now just toggling on/off with env
    slack_enabled = System.get_env("PAPERCUPS_SLACK_ENABLED")
    url = "https://www.papercups.io/conversations/" <> conversation_id
    description = "conversation " <> conversation_id
    link = "<#{url}|#{description}>"
    subject = "New message in " <> link

    payload = %{
      "text" => subject,
      "attachments" => [%{"text" => text}]
    }

    if slack_enabled do
      send(payload)
    else
      # Inspect what would've been sent for debugging
      IO.inspect(payload)
    end
  end
end
