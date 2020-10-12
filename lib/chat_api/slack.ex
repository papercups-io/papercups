defmodule ChatApi.Slack do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  require Logger

  use Tesla

  alias ChatApi.{Conversations, SlackAuthorizations, SlackConversationThreads, Users}
  alias ChatApi.Customers.Customer

  plug Tesla.Middleware.BaseUrl, "https://slack.com/api"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json; charset=utf-8"}
  ]

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

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

  @spec log(binary()) :: :ok | Tesla.Env.result()
  def log(message) do
    case System.get_env("PAPERCUPS_SLACK_WEBHOOK_URL") do
      "https://hooks.slack.com/services/" <> _rest = url ->
        log(message, url)

      _ ->
        Logger.info("Slack log: #{inspect(message)}")
    end
  end

  @spec log(binary(), binary()) :: Tesla.Env.result()
  def log(message, webhook_url) do
    [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"content-type", "application/json"}]}
    ]
    |> Tesla.client()
    |> Tesla.post(webhook_url, %{"text" => message})
  end

  @spec should_execute?(binary()) :: boolean()
  def should_execute?(access_token) do
    Mix.env() != :test && is_valid_access_token?(access_token)
  end

  @spec get_user_email(binary(), binary()) :: nil | binary()
  def get_user_email(user_id, access_token) do
    with {:ok, response} <- retrieve_user_info(user_id, access_token) do
      try do
        extract_slack_user_email(response)
      rescue
        error ->
          Logger.error("Unable to retrieve Slack user email: #{inspect(error)}")

          nil
      end
    end
  end

  # Look for a match between the Slack sender and internal Papercups users
  # to try to identify the sender; falls back to the default assignee id.
  @spec get_sender_id(Conversations.Conversation.t(), binary()) :: binary()
  def get_sender_id(conversation, user_id) do
    %{account_id: account_id, assignee_id: assignee_id} = conversation
    %{access_token: access_token} = get_slack_authorization(account_id)

    user_id
    |> get_user_email(access_token)
    |> Users.find_user_by_email(account_id)
    |> case do
      %{id: id} -> id
      _ -> assignee_id
    end
  end

  @spec get_access_token(binary()) :: Tesla.Env.result()
  def get_access_token(code) do
    client_id = System.get_env("PAPERCUPS_SLACK_CLIENT_ID")
    client_secret = System.get_env("PAPERCUPS_SLACK_CLIENT_SECRET")

    get("/oauth.v2.access",
      query: [code: code, client_id: client_id, client_secret: client_secret]
    )
  end

  @spec send_conversation_message_alert(binary(), binary(), keyword()) ::
          Tesla.Env.result() | nil | :ok
  def send_conversation_message_alert(conversation_id, text, type: type) do
    # Check if a Slack thread already exists for this conversation.
    # If one exists, send followup messages as replies; otherwise, start a new thread
    thread = SlackConversationThreads.get_thread_by_conversation_id(conversation_id)

    %{account_id: account_id, customer: customer} =
      Conversations.get_conversation_with!(conversation_id, :customer)

    %{access_token: access_token, channel: channel} = get_slack_authorization(account_id)

    # TODO: use a struct here?
    %{
      customer: customer,
      text: text,
      conversation_id: conversation_id,
      type: type,
      thread: thread
    }
    |> get_message_text()
    |> get_message_payload(%{
      channel: channel,
      customer: customer,
      thread: thread
    })
    |> send_message(access_token)
    |> case do
      # Just pass through in test/dev mode (not sure if there's a more idiomatic way to do this)
      {:ok, nil} ->
        nil

      {:ok, response} ->
        # If no thread exists yet, start a new thread and kick off the first reply
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

      error ->
        Logger.error("Unable to send Slack message: #{inspect(error)}")
    end
  end

  @spec get_conversation_account_id(binary()) :: binary() | nil
  def get_conversation_account_id(conversation_id) do
    with %{account_id: account_id} <- Conversations.get_conversation!(conversation_id) do
      account_id
    else
      # TODO: better error handling
      _error -> nil
    end
  end

  @spec get_slack_authorization(binary()) ::
          %{access_token: binary(), channel: binary()}
          | SlackAuthorizations.SlackAuthorization.t()
  def get_slack_authorization(account_id) do
    case SlackAuthorizations.get_authorization_by_account(account_id) do
      # Supports a fallback access token as an env variable to make it easier to
      # test locally (assumes the existence of a "bots" channel in your workspace)
      nil -> %{access_token: get_default_access_token(), channel: "#bots"}
      auth -> auth
    end
  end

  # TODO: not sure the most idiomatic way to handle this, but basically this
  # just formats how we show the name/email of the customer if they exist
  @spec identify_customer(Customer.t()) :: binary()
  def identify_customer(%Customer{} = %{email: email, name: name}) do
    case [name, email] do
      [nil, nil] -> "Anonymous User"
      [x, nil] -> x
      [nil, y] -> y
      [x, y] -> "#{x} (#{y})"
    end
  end

  @spec get_message_text(map()) :: binary()
  def get_message_text(%{
        customer: customer,
        text: text,
        conversation_id: conversation_id,
        type: :customer,
        thread: nil
      }) do
    url = System.get_env("BACKEND_URL") || ""

    base =
      if Mix.env() == :dev do
        "http://localhost:3000"
      else
        "https://" <> url
      end

    url = base <> "/conversations/" <> conversation_id
    dashboard = "<#{url}|dashboard>"

    "*:wave: #{identify_customer(customer)} says*: #{text}" <>
      "\n\nReply to this thread to start chatting, or view in the #{dashboard} :rocket:"
  end

  def get_message_text(%{
        customer: customer,
        text: text,
        type: type,
        conversation_id: _conversation_id,
        thread: _thread
      }) do
    case type do
      :agent -> "*:female-technologist: Agent*: #{text}"
      :customer -> "*:wave: #{identify_customer(customer)}*: #{text}"
      _ -> raise "Unrecognized sender type: " <> type
    end
  end

  @spec get_message_payload(binary(), map()) :: map()
  def get_message_payload(text, %{
        channel: channel,
        customer: %{
          name: name,
          email: email,
          current_url: current_url,
          browser: browser,
          os: os
        },
        thread: nil
      }) do
    %{
      "channel" => channel,
      "blocks" => [
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => text
          }
        },
        %{
          "type" => "section",
          "fields" => [
            %{
              "type" => "mrkdwn",
              "text" => "*Name:*\n#{name || "Anonymous User"}"
            },
            %{
              "type" => "mrkdwn",
              "text" => "*Email:*\n#{email || "N/A"}"
            },
            %{
              "type" => "mrkdwn",
              "text" => "*URL:*\n#{current_url || "N/A"}"
            },
            %{
              "type" => "mrkdwn",
              "text" => "*Browser:*\n#{browser || "N/A"}"
            },
            %{
              "type" => "mrkdwn",
              "text" => "*OS:*\n#{os || "N/A"}"
            }
          ]
        }
      ]
    }
  end

  def get_message_payload(text, %{
        channel: channel,
        customer: _customer,
        thread: %{slack_thread_ts: slack_thread_ts}
      }) do
    %{
      "channel" => channel,
      "text" => text,
      "thread_ts" => slack_thread_ts
    }
  end

  def get_message_payload(text, params) do
    raise "Unrecognized params for Slack payload: #{text} #{inspect(params)}"
  end

  @spec create_new_slack_conversation_thread(binary(), map()) ::
          {:ok, SlackConversationThreads.t()} | {:error, Ecto.Changeset.t()}
  def create_new_slack_conversation_thread(conversation_id, response) do
    with conversation <- Conversations.get_conversation_with!(conversation_id, account: :users),
         primary_user_id <- get_conversation_primary_user_id(conversation) do
      # TODO: This is just a temporary workaround to handle having a user_id
      # in the message when an agent responds on Slack. At the moment, if anyone
      # responds to a thread on Slack, we just assume it's the assignee.
      assign_and_broadcast_conversation_updated(conversation, primary_user_id)

      %{
        conversation_id: conversation_id,
        account_id: conversation.account_id
      }
      |> Map.merge(extract_slack_conversation_thread_info(response))
      |> SlackConversationThreads.create_slack_conversation_thread()
    end
  end

  @spec assign_and_broadcast_conversation_updated(map(), binary()) :: :ok | {:error, term()}
  def assign_and_broadcast_conversation_updated(conversation, primary_user_id) do
    %{id: conversation_id, account_id: account_id} = conversation

    {:ok, update} =
      Conversations.update_conversation(conversation, %{assignee_id: primary_user_id})

    result = ChatApiWeb.ConversationView.render("basic.json", conversation: update)

    ChatApiWeb.Endpoint.broadcast!("notification:" <> account_id, "conversation:updated", %{
      "id" => conversation_id,
      "updates" => result
    })
  end

  @spec get_conversation_primary_user_id(Conversations.Conversation.t()) :: binary()
  def get_conversation_primary_user_id(conversation) do
    # FIXME: this includes disabled users!
    # TODO: do a round robin here instead of just getting the first user every time?
    conversation
    |> Map.get(:account)
    |> Map.get(:users)
    |> fetch_valid_user()
  end

  @spec fetch_valid_user(list()) :: binary()
  def fetch_valid_user([]),
    do: raise("No users associated with the conversation's account")

  def fetch_valid_user(users) do
    users
    |> Enum.reject(& &1.disabled_at)
    |> Enum.sort_by(& &1.inserted_at)
    |> List.first()
    |> Map.get(:id)
  end

  @spec is_valid_access_token?(binary()) :: boolean()
  def is_valid_access_token?(token) do
    case token do
      "xoxb-" <> _rest -> true
      _ -> false
    end
  end

  @spec extract_slack_conversation_thread_info(map()) :: map()
  def extract_slack_conversation_thread_info(%{body: body}) do
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

  @spec extract_slack_user_email(map()) :: binary()
  def extract_slack_user_email(%{body: body}) do
    if Map.get(body, "ok") do
      get_in(body, ["user", "profile", "email"])
    else
      Logger.error("Error retrieving user info: #{inspect(body)}")

      raise "users.info returned ok=false"
    end
  end

  @spec get_default_access_token() :: binary() | nil
  defp get_default_access_token() do
    token = System.get_env("SLACK_BOT_ACCESS_TOKEN")

    if is_valid_access_token?(token) do
      token
    else
      nil
    end
  end
end
