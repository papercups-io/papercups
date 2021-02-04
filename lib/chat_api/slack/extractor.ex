defmodule ChatApi.Slack.Extractor do
  require Logger

  @spec extract_slack_message(map()) :: {:ok, map()} | {:error, String.t()}
  def extract_slack_message(%{body: %{"ok" => true, "messages" => [message | _]}}),
    do: {:ok, message}

  def extract_slack_message(%{body: %{"ok" => true, "messages" => []}}),
    do: {:error, "No messages were found"}

  def extract_slack_message(%{body: %{"ok" => false} = body}) do
    Logger.error("conversations.history returned ok=false: #{inspect(body)}")

    {:error, "conversations.history returned ok=false: #{inspect(body)}"}
  end

  def extract_slack_message(response),
    do: {:error, "Invalid response: #{inspect(response)}"}

  @spec extract_slack_messages(map()) :: {:ok, [map()]} | {:error, String.t()}
  def extract_slack_messages(%{body: %{"ok" => true, "messages" => messages}})
      when is_list(messages),
      do: {:ok, messages}

  def extract_slack_messages(%{body: %{"ok" => false} = body}) do
    Logger.error("conversations.replies returned ok=false: #{inspect(body)}")

    {:error, "conversations.replies returned ok=false: #{inspect(body)}"}
  end

  def extract_slack_messages(response),
    do: {:error, "Invalid response: #{inspect(response)}"}

  @spec extract_slack_channel(map()) :: {:ok, map()} | {:error, String.t()}
  def extract_slack_channel(%{body: %{"ok" => true, "channel" => channel}}) when is_map(channel),
    do: {:ok, channel}

  def extract_slack_channel(%{body: %{"ok" => false} = body}) do
    Logger.error("conversations.info returned ok=false: #{inspect(body)}")

    {:error, "conversations.info returned ok=false: #{inspect(body)}"}
  end

  def extract_slack_channel(response),
    do: {:error, "Invalid response: #{inspect(response)}"}

  @slackbot_user_id "USLACKBOT"

  @spec extract_valid_slack_users(map()) :: {:ok, [map()]} | {:error, String.t()}
  def extract_valid_slack_users(%{body: %{"ok" => true, "members" => members}}) do
    users =
      Enum.reject(members, fn member ->
        Map.get(member, "is_bot") ||
          Map.get(member, "deleted") ||
          member["id"] == @slackbot_user_id
      end)

    {:ok, users}
  end

  def extract_valid_slack_users(%{body: %{"ok" => true, "members" => []}}),
    do: {:error, "No users were found"}

  def extract_valid_slack_users(response),
    do: {:error, "Invalid response: #{inspect(response)}"}

  # TODO: refactor extractors below to return :ok/:error tuples rather than raising?

  @spec extract_slack_conversation_thread_info!(map()) :: map()
  def extract_slack_conversation_thread_info!(%{body: body}) do
    if Map.get(body, "ok") do
      %{
        slack_channel: Map.get(body, "channel"),
        slack_thread_ts: Map.get(body, "ts")
      }
    else
      Logger.error("Error sending Slack message: #{inspect(body)}")

      raise "chat.postMessage returned ok=false"
    end
  end

  @spec extract_slack_user_email!(map()) :: binary()
  def extract_slack_user_email!(%{body: body}) do
    if Map.get(body, "ok") do
      get_in(body, ["user", "profile", "email"])
    else
      Logger.error("Error retrieving user info: #{inspect(body)}")

      raise "users.info returned ok=false"
    end
  end
end
