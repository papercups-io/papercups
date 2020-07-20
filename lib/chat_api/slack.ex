defmodule ChatApi.Slack do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  use Tesla

  alias ChatApi.{Conversations, SlackConversationThreads}

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
    thread = SlackConversationThreads.get_thread_by_conversation_id(conversation_id)

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

    # TODO: clean up a bit
    payload =
      if is_nil(thread) do
        %{
          "channel" => "#bots",
          "text" => subject,
          "attachments" => [%{"text" => text}]
        }
      else
        %{
          "channel" => "#bots",
          "attachments" => [%{"text" => text}],
          "thread_ts" => thread.slack_thread_ts
        }
      end

    if slack_enabled do
      {:ok, response} = send_message(payload)

      # TODO: clean up a bit
      if is_nil(thread) do
        result = create_new_slack_conversation_thread(conversation_id, response)

        result
      end
    else
      # Inspect what would've been sent for debugging
      IO.inspect(payload)
    end
  end

  def create_new_slack_conversation_thread(conversation_id, response) do
    # TODO: use a `with` statement here for better error handling?
    conversation = Conversations.get_conversation!(conversation_id)

    params =
      Map.merge(
        %{conversation_id: conversation_id, account_id: conversation.account_id},
        extract_slack_conversation_thread_info(response)
      )

    SlackConversationThreads.create_slack_conversation_thread(params)
  end

  defp extract_slack_conversation_thread_info(%{body: body}) do
    if Map.get(body, "ok") do
      %{
        slack_channel: Map.get(body, "channel"),
        slack_thread_ts: Map.get(body, "ts")
      }
    else
      raise "chat.postMessage returned ok=false"
    end
  end
end
