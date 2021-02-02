defmodule ChatApi.Slack.Helpers do
  @moduledoc """
  Utility methods for interacting with Slack
  """

  require Logger

  alias ChatApi.{
    Companies,
    Conversations,
    Customers,
    Slack,
    SlackAuthorizations,
    SlackConversationThreads,
    Users
  }

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message
  alias ChatApi.SlackAuthorizations.SlackAuthorization
  alias ChatApi.SlackConversationThreads.SlackConversationThread
  alias ChatApi.Users.User

  @spec get_user_email(binary(), binary()) :: nil | binary()
  def get_user_email(slack_user_id, access_token) do
    case Slack.Client.retrieve_user_info(slack_user_id, access_token) do
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

  @spec get_slack_username(binary(), binary()) :: nil | binary()
  def get_slack_username(slack_user_id, access_token) do
    with {:ok, response} <- Slack.Client.retrieve_user_info(slack_user_id, access_token),
         %{body: %{"ok" => true, "user" => %{"name" => username} = user}} <- response do
      [
        get_in(user, ["profile", "display_name"]),
        get_in(user, ["profile", "real_name"]),
        username
      ]
      |> Enum.filter(fn value ->
        case value do
          nil -> false
          "" -> false
          value when not is_binary(value) -> false
          _value -> true
        end
      end)
      |> List.first()
    else
      error ->
        Logger.error("Unable to retrieve Slack username: #{inspect(error)}")

        nil
    end
  end

  @spec find_or_create_customer_from_slack_user_id(any(), binary(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def find_or_create_customer_from_slack_user_id(authorization, slack_user_id, slack_channel_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "user" => user}}} <-
           Slack.Client.retrieve_user_info(slack_user_id, access_token),
         %{"profile" => %{"email" => email} = profile} <- user do
      company_attrs =
        case Companies.find_by_slack_channel(account_id, slack_channel_id) do
          %{id: company_id} -> %{company_id: company_id}
          _ -> %{}
        end

      attrs =
        %{
          name: Map.get(profile, "real_name"),
          time_zone: Map.get(user, "tz")
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()
        |> Map.merge(company_attrs)

      Customers.find_or_create_by_email(email, account_id, attrs)
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

  # NB: this is basically the same as `find_or_create_customer_from_slack_user_id` above,
  # but keeping both with duplicate code for now since we may get rid of one in the near future
  @spec create_or_update_customer_from_slack_user_id(any(), binary(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def create_or_update_customer_from_slack_user_id(authorization, slack_user_id, slack_channel_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "user" => user}}} <-
           Slack.Client.retrieve_user_info(slack_user_id, access_token),
         %{"profile" => %{"email" => email} = profile} <- user do
      company_attrs =
        case Companies.find_by_slack_channel(account_id, slack_channel_id) do
          %{id: company_id} -> %{company_id: company_id}
          _ -> %{}
        end

      attrs =
        %{
          name: Map.get(profile, "real_name"),
          time_zone: Map.get(user, "tz"),
          profile_photo_url: Map.get(profile, "image_original")
        }
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> Map.new()
        |> Map.merge(company_attrs)

      Customers.create_or_update_by_email(email, account_id, attrs)
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
        |> Customers.find_by_email(account_id)

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
        |> Users.find_user_by_email(account_id)

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

  @spec is_private_slack_channel?(binary()) :: boolean()
  def is_private_slack_channel?("G" <> _rest), do: true
  def is_private_slack_channel?("C" <> _rest), do: false
  def is_private_slack_channel?(_), do: false

  @spec get_slack_authorization(binary()) ::
          %{access_token: binary(), channel: binary(), channel_id: binary()}
          | SlackAuthorization.t()
  def get_slack_authorization(account_id) do
    case SlackAuthorizations.get_authorization_by_account(account_id) do
      # Supports a fallback access token as an env variable to make it easier to
      # test locally (assumes the existence of a "bots" channel in your workspace)
      # TODO: deprecate
      nil ->
        %{
          access_token: Slack.Token.get_default_access_token(),
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
  def identify_customer(%Customer{email: email, name: name}) do
    case [name, email] do
      [nil, nil] -> "Anonymous User"
      [x, nil] -> x
      [nil, y] -> y
      [x, y] -> "#{x} (#{y})"
    end
  end

  @spec create_new_slack_conversation_thread(binary(), map()) ::
          {:ok, SlackConversationThread.t()} | {:error, Ecto.Changeset.t()}
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

  def is_bot_message?(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: true
  def is_bot_message?(_), do: false

  @spec sanitize_slack_message(binary(), SlackAuthorization.t()) :: binary()
  def sanitize_slack_message(text, %SlackAuthorization{
        access_token: access_token
      }) do
    text
    |> sanitize_slack_user_ids(access_token)
    |> sanitize_slack_links()
    |> sanitize_slack_mailto_links()
  end

  @spec get_slack_message_metadata(binary()) :: map() | nil
  def get_slack_message_metadata(text) do
    %{
      mentions: Slack.Helpers.find_slack_user_mentions(text),
      links: Slack.Helpers.find_slack_links(text),
      mailto_links: Slack.Helpers.find_slack_mailto_links(text)
    }
    |> Enum.filter(fn {_key, value} ->
      case value do
        nil -> false
        [] -> false
        "" -> false
        _ -> true
      end
    end)
    |> case do
      [] -> nil
      list -> Map.new(list)
    end
  end

  @slack_user_id_regex ~r/<@U(.*?)>/
  @slack_link_regex ~r/<http(.*?)>/
  @slack_mailto_regex ~r/<mailto(.*?)>/

  @spec find_slack_user_mentions(binary()) :: [binary()]
  def find_slack_user_mentions(text) do
    @slack_user_id_regex
    |> Regex.scan(text)
    |> Enum.map(fn [match, _id] -> match end)
  end

  @spec sanitize_slack_user_ids(binary(), binary()) :: binary()
  def sanitize_slack_user_ids(text, access_token) do
    case Regex.scan(@slack_user_id_regex, text) do
      [] ->
        text

      results ->
        Enum.reduce(results, text, fn [match, id], acc ->
          # TODO: figure out best way to handle unrecognized user IDs
          slack_user_id = "U#{id}"

          case get_slack_username(slack_user_id, access_token) do
            nil -> acc
            username -> String.replace(acc, match, "@#{username}")
          end
        end)
    end
  end

  @spec find_slack_links(binary()) :: [binary()]
  def find_slack_links(text) do
    @slack_link_regex
    |> Regex.scan(text)
    |> Enum.map(fn [match, _] -> match end)
  end

  @spec sanitize_slack_links(binary()) :: binary()
  def sanitize_slack_links(text) do
    case Regex.scan(@slack_link_regex, text) do
      [] ->
        text

      results ->
        Enum.reduce(results, text, fn [match, _], acc ->
          markdown = slack_link_to_markdown(match)

          String.replace(acc, match, markdown)
        end)
    end
  end

  @spec find_slack_mailto_links(binary()) :: [binary()]
  def find_slack_mailto_links(text) do
    @slack_mailto_regex
    |> Regex.scan(text)
    |> Enum.map(fn [match, _] -> match end)
  end

  @spec sanitize_slack_mailto_links(binary()) :: binary()
  def sanitize_slack_mailto_links(text) do
    case Regex.scan(@slack_mailto_regex, text) do
      [] ->
        text

      results ->
        Enum.reduce(results, text, fn [match, _], acc ->
          markdown = slack_link_to_markdown(match)

          String.replace(acc, match, markdown)
        end)
    end
  end

  @spec slack_link_to_markdown(binary()) :: binary()
  def slack_link_to_markdown(text) do
    text
    |> String.replace(["<", ">"], "")
    |> String.split("|")
    |> case do
      [link] -> "[#{link}](#{link})"
      [link, display] -> "[#{display}](#{link})"
      _ -> text
    end
  end

  @spec slack_ts_to_utc(binary()) :: DateTime.t()
  def slack_ts_to_utc(ts) do
    with {unix, _} <- Float.parse(ts),
         microseconds <- round(unix * 1_000_000),
         {:ok, datetime} <- DateTime.from_unix(microseconds, :microsecond) do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  #####################
  # Extractors
  #####################

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
        conversation: %Conversation{id: conversation_id, customer: %Customer{} = customer},
        message: %Message{body: text},
        authorization: _authorization,
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

  @slack_chat_write_customize_scope "chat:write.customize"

  def get_message_text(%{
        conversation: %Conversation{} = conversation,
        message: %Message{body: text} = message,
        authorization: %SlackAuthorization{} = authorization,
        thread: %SlackConversationThread{}
      }) do
    if SlackAuthorizations.has_authorization_scope?(
         authorization,
         @slack_chat_write_customize_scope
       ) do
      text
    else
      case message do
        %Message{user: %User{} = user} ->
          "*:female-technologist: #{Slack.Notification.format_user_name(user)}*: #{text}"

        %Message{customer: %Customer{} = customer} ->
          "*:wave: #{identify_customer(customer)}*: #{text}"

        %Message{customer_id: nil, user_id: user_id} when not is_nil(user_id) ->
          "*:female-technologist: Agent*: #{text}"

        %Message{customer_id: customer_id, user_id: nil} when not is_nil(customer_id) ->
          "*:wave: #{identify_customer(conversation.customer)}*: #{text}"

        _ ->
          Logger.error("Unrecognized message format: #{inspect(message)}")

          text
      end
    end
  end

  @spec get_message_payload(binary(), map()) :: map()
  def get_message_payload(text, %{
        channel: channel,
        customer: %Customer{
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
        message: %Message{user: %User{} = user} = message,
        thread: %SlackConversationThread{slack_thread_ts: slack_thread_ts}
      }) do
    %{
      "channel" => channel,
      "text" => text,
      "thread_ts" => slack_thread_ts,
      # TODO: figure out where these methods should live
      "username" => Slack.Notification.format_user_name(user),
      "icon_url" => Slack.Notification.slack_icon_url(user),
      "reply_broadcast" => reply_broadcast_enabled?(message)
    }
  end

  def get_message_payload(text, %{
        channel: channel,
        customer: _customer,
        message: %Message{customer: %Customer{} = customer} = message,
        thread: %SlackConversationThread{slack_thread_ts: slack_thread_ts}
      }) do
    %{
      "channel" => channel,
      "text" => text,
      "thread_ts" => slack_thread_ts,
      "username" => identify_customer(customer),
      "icon_emoji" => ":wave:",
      "reply_broadcast" => reply_broadcast_enabled?(message)
    }
  end

  def get_message_payload(text, params) do
    raise "Unrecognized params for Slack payload: #{text} #{inspect(params)}"
  end

  @spec send_internal_notification(binary()) :: any()
  def send_internal_notification(message) do
    Logger.info(message)
    # Putting in an async Task for now, since we don't care if this succeeds
    # or fails (and we also don't want it to block anything)
    Task.start(fn -> Slack.Notification.log(message) end)
  end

  @spec reply_broadcast_enabled?(Message.t()) :: boolean()
  # We only want to enable this for messages from customers
  defp reply_broadcast_enabled?(%Message{
         account_id: account_id,
         customer: %Customer{} = _customer
       }) do
    # TODO: figure out a better way to enable feature flags for certain accounts,
    # or just make this configurable in account settings (or something like that)
    case System.get_env("PAPERCUPS_FEATURE_FLAGGED_ACCOUNTS") do
      ids when is_binary(ids) -> ids |> String.split(" ") |> Enum.member?(account_id)
      _ -> false
    end
  end

  defp reply_broadcast_enabled?(_message), do: false
end
