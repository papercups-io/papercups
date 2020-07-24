defmodule ChatApi.Slack do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  use Tesla

  alias ChatApi.{Conversations, SlackAuthorizations, SlackConversationThreads}

  plug Tesla.Middleware.BaseUrl, "https://slack.com/api"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
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
  def send_message(message, access_token) do
    post("/chat.postMessage", message,
      headers: [
        {"Authorization", "Bearer " <> access_token}
      ]
    )
  end

  def get_access_token(code) do
    client_id = System.get_env("PAPERCUPS_SLACK_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_SLACK_CLIENT_SECRET")

    get("/oauth.v2.access",
      query: [code: code, client_id: client_id, client_secret: client_secret]
    )
  end

  def send_conversation_message_alert(conversation_id, text, type: type) do
    conversation = Conversations.get_conversation!(conversation_id)
    thread = SlackConversationThreads.get_thread_by_conversation_id(conversation_id)
    %{account_id: account_id} = conversation

    %{access_token: access_token, channel: channel} =
      case SlackAuthorizations.get_authorization_by_account(account_id) do
        nil -> %{access_token: get_default_access_token(), channel: "#bots"}
        auth -> auth
      end

    # TODO: clean up a bit?
    payload =
      case thread do
        nil ->
          subject = get_initial_slack_thread_subject(conversation_id)

          %{
            "channel" => channel,
            "text" => subject,
            "attachments" => [%{"text" => text}]
          }

        %{slack_thread_ts: slack_thread_ts} ->
          subject = get_slack_reply_subject(type)

          %{
            "channel" => channel,
            "text" => subject,
            "attachments" => [%{"text" => text}],
            "thread_ts" => slack_thread_ts
          }
      end

    slack_enabled = is_valid_access_token(access_token)

    if slack_enabled do
      {:ok, response} = send_message(payload, access_token)

      # If no thread exists yet, start a new thread and kick off the first reply
      # TODO: clean up a bit
      if is_nil(thread) do
        {:ok, thread} = create_new_slack_conversation_thread(conversation_id, response)

        send_message(
          %{
            "channel" => channel,
            "text" => "(Send a message here to get started!)",
            "thread_ts" => thread.slack_thread_ts
          },
          access_token
        )
      end
    else
      # Inspect what would've been sent for debugging
      IO.inspect(payload)
    end
  end

  def get_initial_slack_thread_subject(conversation_id) do
    # TODO: use env variables here?
    base =
      if Mix.env() == :dev do
        "http://localhost:3000"
      else
        "https://app.papercups.io"
      end

    url = base <> "/conversations/" <> conversation_id
    description = "conversation " <> conversation_id
    link = "<#{url}|#{description}>"

    subject =
      "New conversation started: " <>
        link <> "\n\nReply to this thread to chat with the customer :rocket:"

    subject
  end

  def get_slack_reply_subject(type) do
    if type == "agent" do
      ":female-technologist: Agent:"
    else
      ":wave: Customer:"
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

  defp is_valid_access_token(token) do
    case token do
      "xoxb-" <> _rest -> true
      _ -> false
    end
  end

  defp get_default_access_token() do
    token = System.get_env("SLACK_BOT_ACCESS_TOKEN")

    if is_valid_access_token(token) do
      token
    else
      nil
    end
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
