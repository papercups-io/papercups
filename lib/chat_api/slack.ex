defmodule ChatApi.Slack do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://slack.com/api"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"},
    {"Authorization", "Bearer " <> System.get_env("SLACK_BOT_ACCESS_TOKEN")}
  ]

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  @doc """
  `message` looks like:

  %{
    "channel" => "#bots",
    "text" => "Testing another reply",
    "attachments" => [%{"text" => "This is some other message"}],
    "thread_ts" => "1595255129.000500" # For replying in thread
  }
  """
  def send_message(message) do
    post("/chat.postMessage", message)
  end

  def send_conversation_message_alert(conversation_id, text) do
    # TODO: handle this in user settings, for now just toggling on/off with env
    slack_enabled = System.get_env("SLACK_BOT_ACCESS_TOKEN")

    base =
      if Mix.env() == :dev do
        "http://localhost:3000"
      else
        "https://www.papercups.io"
      end

    url = base <> "/conversations/" <> conversation_id
    description = "conversation " <> conversation_id
    link = "<#{url}|#{description}>"
    subject = "New message in " <> link

    payload = %{
      "channel" => "#bots",
      "text" => subject,
      "attachments" => [%{"text" => text}]
    }

    if slack_enabled do
      send_message(payload)
    else
      # Inspect what would've been sent for debugging
      IO.inspect(payload)
    end
  end
end
