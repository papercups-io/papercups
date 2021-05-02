defmodule ChatApi.Slack.Client do
  @moduledoc """
  A module for interacting with the Slack API.
  """

  require Logger

  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://slack.com/api")

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ])

  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  @spec get_access_token(binary()) :: Tesla.Env.result()
  def get_access_token(code) do
    client_id = System.get_env("PAPERCUPS_SLACK_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_SLACK_CLIENT_SECRET")

    get("/oauth.v2.access",
      query: [code: code, client_id: client_id, client_secret: client_secret]
    )
  end

  @spec get_access_token(binary(), binary() | nil) :: Tesla.Env.result()
  def get_access_token(code, nil) do
    case System.get_env("PAPERCUPS_SLACK_REDIRECT_URI") do
      nil -> get_access_token(code)
      redirect_uri -> get_access_token(code, redirect_uri)
    end
  end

  def get_access_token(code, redirect_uri) do
    client_id = System.get_env("PAPERCUPS_SLACK_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_SLACK_CLIENT_SECRET")

    get("/oauth.v2.access",
      query: [
        code: code,
        redirect_uri: redirect_uri,
        client_id: client_id,
        client_secret: client_secret
      ]
    )
  end

  @spec send_message(map(), binary()) :: Tesla.Env.result() | {:ok, nil}
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
    if should_execute?(access_token) do
      post("/chat.postMessage", message,
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      # Inspect what would've been sent for debugging
      Logger.info("Would have sent to Slack: #{inspect(message)}")

      {:ok, nil}
    end
  end

  @spec list_messages(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def list_messages(channel, access_token) do
    if should_execute?(access_token) do
      get("/conversations.history",
        query: [channel: channel],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      # Inspect what would've been sent for debugging
      Logger.info("Would have retrieved messages from channel #{inspect(channel)}")

      {:ok, nil}
    end
  end

  @spec retrieve_message(binary(), binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def retrieve_message(channel, ts, access_token) do
    if should_execute?(access_token) do
      get("/conversations.history",
        query: [channel: channel, latest: ts, limit: 1, inclusive: true],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      # Inspect what would've been sent for debugging
      Logger.info("Would have retrieved message #{inspect(ts)} from channel #{inspect(channel)}")

      {:ok, nil}
    end
  end

  @spec update_message(binary(), binary(), map(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def update_message(channel, ts, updates, access_token) do
    if should_execute?(access_token) do
      post(
        "/chat.update",
        Map.merge(updates, %{"channel" => channel, "ts" => ts}),
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      # Inspect what would've been sent for debugging
      Logger.info("Would have retrieved message #{inspect(ts)} from channel #{inspect(channel)}")

      {:ok, nil}
    end
  end

  @spec get_message_permalink(binary(), binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def get_message_permalink(channel, ts, access_token) do
    if should_execute?(access_token) do
      get("/chat.getPermalink",
        query: [channel: channel, message_ts: ts],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      # Inspect what would've been sent for debugging
      Logger.info(
        "Would have gotten permalink for message #{inspect(ts)} from channel #{inspect(channel)}"
      )

      {:ok, nil}
    end
  end

  @spec retrieve_user_info(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def retrieve_user_info(user_id, access_token) do
    if should_execute?(access_token) do
      get("/users.info",
        query: [user: user_id],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      Logger.info("Invalid access token")

      {:ok, nil}
    end
  end

  @spec retrieve_bot_info(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def retrieve_bot_info(bot_id, access_token) do
    if should_execute?(access_token) do
      get("/bots.info",
        query: [bot: bot_id],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      Logger.info("Invalid access token")

      {:ok, nil}
    end
  end

  @spec list_channels(binary()) :: {:ok, nil} | Tesla.Env.result()
  def list_channels(access_token) do
    # TODO: we need channels:read scope to access this
    if should_execute?(access_token) do
      get("/conversations.list",
        query: [types: "public_channel,private_channel"],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      Logger.info("Invalid access token")

      {:ok, nil}
    end
  end

  @spec list_users(binary()) :: {:ok, nil} | Tesla.Env.result()
  def list_users(access_token) do
    if should_execute?(access_token) do
      get("/users.list",
        query: [],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      Logger.info("Invalid access token")

      {:ok, nil}
    end
  end

  @spec retrieve_channel_info(binary(), binary()) :: {:ok, nil} | Tesla.Env.result()
  def retrieve_channel_info(channel, access_token) do
    # NB: we need channels:read scope to access this
    if should_execute?(access_token) do
      get("/conversations.info",
        query: [channel: channel],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      Logger.info("Invalid access token")

      {:ok, nil}
    end
  end

  @spec retrieve_conversation_replies(binary(), binary(), binary()) ::
          {:ok, nil} | Tesla.Env.result()
  def retrieve_conversation_replies(channel, thread_ts, access_token) do
    if should_execute?(access_token) do
      get("/conversations.replies",
        query: [channel: channel, ts: thread_ts],
        headers: [
          {"Authorization", "Bearer " <> access_token}
        ]
      )
    else
      Logger.info("Invalid access token")

      {:ok, nil}
    end
  end

  @spec should_execute?(binary()) :: boolean()
  defp should_execute?(access_token) do
    Application.get_env(:chat_api, :environment) != :test &&
      ChatApi.Slack.Token.is_valid_access_token?(access_token)
  end
end
