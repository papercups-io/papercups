defmodule ChatApi.Slack.Helpers do
  @moduledoc """
  Utility methods for interacting with Slack
  """

  require Logger

  alias ChatApi.{
    Conversations,
    SlackAuthorizations,
    SlackConversationThreads,
    Users.User,
    Customers.Customer,
    Messages.Message
  }

  @spec get_user_email(binary(), binary()) :: nil | binary()
  def get_user_email(slack_user_id, access_token) do
    case ChatApi.Slack.Client.retrieve_user_info(slack_user_id, access_token) do
      {:ok, nil} ->
        Logger.debug("Invalid Slack token - returning nil for user email")

        nil

      {:ok, response} ->
        try do
          extract_slack_user_email(response)
        rescue
          error ->
            Logger.error("Unable to retrieve Slack user email: #{inspect(error)}")

            nil
        end

      error ->
        Logger.error("Unable to retrieve Slack user info: #{inspect(error)}")

        nil
    end
  end

  @spec find_or_create_customer_from_slack_user_id(any(), binary(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def find_or_create_customer_from_slack_user_id(authorization, slack_user_id, slack_channel_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "user" => user}}} <-
           ChatApi.Slack.Client.retrieve_user_info(slack_user_id, access_token),
         %{"real_name" => name, "tz" => time_zone, "profile" => %{"email" => email}} <- user do
      default_attrs = %{name: name, time_zone: time_zone}

      attrs =
        case ChatApi.Companies.find_by_slack_channel(account_id, slack_channel_id) do
          nil -> default_attrs
          company -> Map.merge(default_attrs, %{company_id: company.id})
        end

      ChatApi.Customers.find_or_create_by_email(email, account_id, attrs)
    else
      # NB: This may occur in test mode, or when the Slack.Client is disabled
      {:ok, error} ->
        Logger.error("Error creating customer from Slack user: #{inspect(error)}")

        error

      error ->
        Logger.error("Error creating customer from Slack user: #{inspect(error)}")

        error
    end
  end

  @spec find_matching_customer(any(), binary()) :: Customer.t() | nil
  def find_matching_customer(authorization, slack_user_id) do
    case authorization do
      %{access_token: access_token, account_id: account_id} ->
        slack_user_id
        |> get_user_email(access_token)
        |> ChatApi.Customers.find_by_email(account_id)

      _ ->
        nil
    end
  end

  @spec find_matching_user(any(), binary()) :: User.t() | nil
  def find_matching_user(authorization, slack_user_id) do
    case authorization do
      %{access_token: access_token, account_id: account_id} ->
        slack_user_id
        |> get_user_email(access_token)
        |> ChatApi.Users.find_user_by_email(account_id)

      _ ->
        nil
    end
  end

  @spec get_admin_sender_id(any(), binary(), binary()) :: binary()
  def get_admin_sender_id(authorization, slack_user_id, fallback) do
    case find_matching_user(authorization, slack_user_id) do
      %{id: id} -> id
      _ -> fallback
    end
  end

  @spec format_sender_id!(any(), binary(), binary()) :: map()
  def format_sender_id!(authorization, slack_user_id, slack_channel_id) do
    # TODO: what's the best way to handle these nested `case` statements?
    # TODO: handle updating the customer's company_id if it's not set yet?
    # TODO: should we check if the slack_user_id is a workspace admin, or something like that?
    case find_matching_user(authorization, slack_user_id) do
      %{id: user_id} ->
        %{"user_id" => user_id}

      _ ->
        case find_matching_customer(authorization, slack_user_id) do
          %{id: customer_id} ->
            %{"customer_id" => customer_id}

          _ ->
            case find_or_create_customer_from_slack_user_id(
                   authorization,
                   slack_user_id,
                   slack_channel_id
                 ) do
              {:ok, customer} ->
                %{"customer_id" => customer.id}

              _ ->
                raise "Unable to find matching user or customer ID for Slack user #{
                        inspect(slack_user_id)
                      } on account authorization #{inspect(authorization)}"
            end
        end
    end
  end

  @spec is_primary_channel?(any(), binary()) :: boolean()
  def is_primary_channel?(authorization, slack_channel_id) do
    case authorization do
      %{channel: channel, channel_id: channel_id} ->
        channel == slack_channel_id || channel_id == slack_channel_id

      _ ->
        false
    end
  end

  @spec get_slack_authorization(binary()) ::
          %{access_token: binary(), channel: binary(), channel_id: binary()}
          | SlackAuthorizations.SlackAuthorization.t()
  def get_slack_authorization(account_id) do
    case SlackAuthorizations.get_authorization_by_account(account_id) do
      # Supports a fallback access token as an env variable to make it easier to
      # test locally (assumes the existence of a "bots" channel in your workspace)
      # TODO: deprecate
      nil ->
        %{
          access_token: ChatApi.Slack.Token.get_default_access_token(),
          channel: "#bots",
          channel_id: "1"
        }

      auth ->
        auth
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
    case Conversations.update_conversation(conversation, %{assignee_id: primary_user_id}) do
      {:ok, update} ->
        ChatApiWeb.Endpoint.broadcast!(
          "notification:" <> conversation.account_id,
          "conversation:updated",
          %{
            "id" => conversation.id,
            "updates" => ChatApiWeb.ConversationView.render("basic.json", conversation: update)
          }
        )

      error ->
        error
    end
  end

  @spec get_conversation_primary_user_id(Conversations.Conversation.t()) :: binary()
  def get_conversation_primary_user_id(conversation) do
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

  @spec get_message_type(Message.t()) :: atom()
  def get_message_type(%Message{customer_id: nil}), do: :agent
  def get_message_type(%Message{user_id: nil}), do: :customer
  def get_message_type(_message), do: :unknown

  #####################
  # Extractors
  #####################

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

  #####################
  # Formatters
  #####################

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

    url = base <> "/conversations/all?cid=" <> conversation_id
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
      # TODO: get agent name, rather than just showing "Agent"
      :agent -> "*:female-technologist: Agent*: #{text}"
      :customer -> "*:wave: #{identify_customer(customer)}*: #{text}"
      :conversation_update -> "_#{text}_"
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
          os: os,
          time_zone: time_zone
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
            },
            %{
              "type" => "mrkdwn",
              "text" => "*Timezone:*\n#{time_zone || "N/A"}"
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
end
