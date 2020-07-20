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

    subject =
      "New conversation started: " <>
        link <> "\n\nReply to this thread to chat with the customer :rocket:"

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

    # TODO: handle this in user settings, for now just toggling on/off
    # based on whether a valid access token is provided as an env variable
    if slack_enabled?() do
      {:ok, response} = send_message(payload)

      # TODO: clean up a bit
      if is_nil(thread) do
        {:ok, thread} = create_new_slack_conversation_thread(conversation_id, response)

        send_message(%{
          "channel" => "#bots",
          "text" => "(Send a message here to get started!)",
          "thread_ts" => thread.slack_thread_ts
        })
      end
    else
      # Inspect what would've been sent for debugging
      IO.inspect(payload)
    end
  end

  def create_new_slack_conversation_thread(conversation_id, response) do
    # TODO: This is just a temporary workaround to handle having a user_id
    # in the message when an agent responds on Slack. At the moment, if anyone
    # responds to a thread on Slack, we just assume it's the assignee.
    with conversation <- Conversations.get_conversation_with!(conversation_id, account: :users),
         primary_user_id = get_conversation_primary_user_id(conversation) do
      params =
        Map.merge(
          %{
            conversation_id: conversation_id,
            account_id: conversation.account_id
          },
          extract_slack_conversation_thread_info(response)
        )

      Conversations.update_conversation(conversation, %{assignee_id: primary_user_id})
      SlackConversationThreads.create_slack_conversation_thread(params)
    end
  end

  defp get_conversation_primary_user_id(conversation) do
    conversation
    |> Map.get(:account)
    |> Map.get(:users)
    |> List.first()
    |> Map.get(:id)
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

  defp slack_enabled? do
    token = System.get_env("SLACK_BOT_ACCESS_TOKEN")

    case token do
      "xoxb-" <> _rest -> true
      "" -> false
      nil -> false
      _ -> raise("Expected Slack access token to match format: xoxb-xxxxx-xxxxx-xxxxxxx")
    end
  end
end
