defmodule ChatApi.Slack.Helpers do
  @moduledoc """
  Utility methods for interacting with Slack
  """

  require Logger

  alias ChatApi.{
    Accounts,
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
          Slack.Extractor.extract_slack_user_email!(response)
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

  @spec find_or_create_customer_from_slack_event(SlackAuthorization.t(), map()) ::
          {:ok, Customer.t()} | {:error, any()}
  def find_or_create_customer_from_slack_event(authorization, %{
        "channel" => slack_channel_id,
        "user" => slack_user_id
      })
      when not is_nil(slack_user_id) and not is_nil(slack_channel_id) do
    find_or_create_customer_from_slack_user_id(authorization, slack_user_id, slack_channel_id)
  end

  def find_or_create_customer_from_slack_event(authorization, %{"bot" => slack_bot_id})
      when not is_nil(slack_bot_id) do
    find_or_create_customer_from_slack_bot_id(authorization, slack_bot_id)
  end

  @spec find_or_create_customer_from_slack_bot_id(any(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def find_or_create_customer_from_slack_bot_id(authorization, slack_bot_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "bot" => bot}}} <-
           Slack.Client.retrieve_bot_info(slack_bot_id, access_token) do
      attrs = customer_params_for_slack_bot(bot)

      Customers.find_or_create_by_external_id(slack_bot_id, account_id, attrs)
    else
      # NB: This may occur in test mode, or when the Slack.Client is disabled
      {:ok, error} ->
        Logger.error("Error creating customer from Slack bot user: #{inspect(error)}")

        error

      error ->
        Logger.error("Error creating customer from Slack bot user: #{inspect(error)}")

        error
    end
  end

  @spec find_or_create_customer_from_slack_user_id(any(), binary(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def find_or_create_customer_from_slack_user_id(authorization, slack_user_id, slack_channel_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "user" => user}}} <-
           Slack.Client.retrieve_user_info(slack_user_id, access_token),
         %{"profile" => %{"email" => email}} <- user do
      company_attrs =
        case Companies.find_by_slack_channel(account_id, slack_channel_id) do
          %{id: company_id} -> %{company_id: company_id}
          _ -> %{}
        end

      attrs = customer_params_for_slack_user(user, company_attrs)

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

  @spec create_or_update_customer_from_slack_event(SlackAuthorization.t(), map()) ::
          {:ok, Customer.t()} | {:error, any()}
  def create_or_update_customer_from_slack_event(authorization, %{
        "channel" => slack_channel_id,
        "user" => slack_user_id
      })
      when not is_nil(slack_user_id) and not is_nil(slack_channel_id) do
    create_or_update_customer_from_slack_user_id(authorization, slack_user_id, slack_channel_id)
  end

  def create_or_update_customer_from_slack_event(authorization, %{"bot" => slack_bot_id})
      when not is_nil(slack_bot_id) do
    create_or_update_customer_from_slack_bot_id(authorization, slack_bot_id)
  end

  @spec create_or_update_customer_from_slack_bot_id(any(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def create_or_update_customer_from_slack_bot_id(authorization, slack_bot_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "bot" => bot}}} <-
           Slack.Client.retrieve_bot_info(slack_bot_id, access_token) do
      create_or_update_customer_from_slack_bot(bot, account_id)
    else
      # NB: This may occur in test mode, or when the Slack.Client is disabled
      {:ok, error} ->
        Logger.error("Error creating customer from Slack bot user: #{inspect(error)}")

        error

      error ->
        Logger.error("Error creating customer from Slack bot user: #{inspect(error)}")

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
           Slack.Client.retrieve_user_info(slack_user_id, access_token) do
      case Companies.find_by_slack_channel(account_id, slack_channel_id) do
        %{id: company_id} ->
          create_or_update_customer_from_slack_user(user, account_id, %{company_id: company_id})

        _ ->
          create_or_update_customer_from_slack_user(user, account_id)
      end
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

  @spec create_or_update_customer_from_slack_user_id(any(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def create_or_update_customer_from_slack_user_id(authorization, slack_user_id) do
    with %{access_token: access_token, account_id: account_id} <- authorization,
         {:ok, %{body: %{"ok" => true, "user" => user}}} <-
           Slack.Client.retrieve_user_info(slack_user_id, access_token) do
      create_or_update_customer_from_slack_user(user, account_id)
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

  @spec customer_params_for_slack_user(map(), map()) :: map()
  def customer_params_for_slack_user(slack_user, attrs \\ %{})

  def customer_params_for_slack_user(%{"profile" => profile} = slack_user, attrs) do
    %{
      name: Map.get(profile, "real_name"),
      time_zone: Map.get(slack_user, "tz"),
      profile_photo_url: Map.get(profile, "image_original")
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.merge(attrs)
  end

  def customer_params_for_slack_user(slack_user, _attrs) do
    Logger.error("Unexpected Slack user: #{inspect(slack_user)}")

    %{}
  end

  @spec create_or_update_customer_from_slack_user(map(), binary(), map()) ::
          {:ok, Customer.t()} | {:error, any()}
  def create_or_update_customer_from_slack_user(slack_user, account_id, attrs \\ %{})

  def create_or_update_customer_from_slack_user(
        %{"profile" => %{"email" => email}} = slack_user,
        account_id,
        attrs
      ) do
    params = customer_params_for_slack_user(slack_user, attrs)

    Customers.create_or_update_by_email(email, account_id, params)
  end

  def create_or_update_customer_from_slack_user(slack_user, _account_id, _attrs) do
    {:error, "Invalid Slack user: #{inspect(slack_user)}"}
  end

  @spec customer_params_for_slack_bot(map()) :: map()
  def customer_params_for_slack_bot(slack_bot) do
    %{
      name: Map.get(slack_bot, "name"),
      profile_photo_url: get_in(slack_bot, ["icons", "image_72"])
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @spec create_or_update_customer_from_slack_bot(map(), binary()) ::
          {:ok, Customer.t()} | {:error, any()}
  def create_or_update_customer_from_slack_bot(slack_bot, account_id)

  def create_or_update_customer_from_slack_bot(
        %{"id" => slack_bot_id} = slack_bot,
        account_id
      ) do
    params = customer_params_for_slack_bot(slack_bot)

    Customers.create_or_update_by_external_id(slack_bot_id, account_id, params)
  end

  def create_or_update_customer_from_slack_bot(slack_bot, _account_id) do
    {:error, "Invalid Slack bot: #{inspect(slack_bot)}"}
  end

  @spec find_matching_customer(SlackAuthorization.t() | nil, binary()) :: Customer.t() | nil
  def find_matching_customer(
        %SlackAuthorization{access_token: access_token, account_id: account_id},
        slack_user_id
      ) do
    slack_user_id
    |> get_user_email(access_token)
    |> Customers.find_by_email(account_id)
  end

  def find_matching_customer(_authorization, _slack_user_id), do: nil

  @spec find_matching_user(SlackAuthorization.t(), binary()) :: User.t() | nil
  def find_matching_user(
        %SlackAuthorization{access_token: access_token, account_id: account_id},
        slack_user_id
      ) do
    slack_user_id
    |> get_user_email(access_token)
    |> Users.find_user_by_email(account_id)
  end

  def find_matching_user(_authorization, _slack_user_id), do: nil

  @spec find_matching_bot_customer(SlackAuthorization.t(), binary()) :: Customer.t() | nil
  def find_matching_bot_customer(%SlackAuthorization{account_id: account_id}, slack_bot_id) do
    Customers.find_by_external_id(slack_bot_id, account_id)
  end

  def find_matching_bot_customer(_authorization, _slack_bot_id), do: nil

  @spec get_admin_sender_id(SlackAuthorization.t(), binary(), binary() | nil) :: binary()
  def get_admin_sender_id(
        %SlackAuthorization{account_id: account_id} = authorization,
        slack_user_id,
        fallback
      ) do
    case find_matching_user(authorization, slack_user_id) do
      %User{id: id} ->
        id

      _ ->
        case fallback do
          nil -> account_id |> Accounts.get_primary_user() |> Map.get(:id)
          fallback_user_id -> fallback_user_id
        end
    end
  end

  @doc """
  Checks for a matching `User` for the Slack message event if the accumulator is `nil`.

  If a matching `User` or `Customer` has already been found, just return it.
  """
  @spec maybe_find_user(User.t() | Customer.t() | nil, SlackAuthorization.t(), map()) ::
          User.t() | Customer.t() | nil
  def maybe_find_user(nil, authorization, %{"user" => slack_user_id}) do
    find_matching_user(authorization, slack_user_id)
  end

  def maybe_find_user(%User{} = user, _, _), do: user
  def maybe_find_user(%Customer{} = customer, _, _), do: customer
  def maybe_find_user(nil, _, _), do: nil

  @doc """
  Checks for a matching `Customer` for the Slack message event if the accumulator is `nil`.

  If a matching `User` or `Customer` has already been found, just return it.
  """
  @spec maybe_find_customer(User.t() | Customer.t() | nil, SlackAuthorization.t(), map()) ::
          User.t() | Customer.t() | nil
  def maybe_find_customer(nil, authorization, %{"bot_id" => slack_bot_id}) do
    find_matching_bot_customer(authorization, slack_bot_id)
  end

  def maybe_find_customer(nil, authorization, %{"user" => slack_user_id}) do
    find_matching_customer(authorization, slack_user_id)
  end

  def maybe_find_customer(%Customer{} = customer, _, _), do: customer
  def maybe_find_customer(%User{} = user, _, _), do: user
  def maybe_find_customer(nil, _, _), do: nil

  @doc """
  Fetches the matching `User` or `Customer` for the Slack message event.
  """
  @spec get_sender_info(SlackAuthorization.t(), map()) :: User.t() | Customer.t() | nil
  def get_sender_info(authorization, slack_message) do
    nil
    |> maybe_find_user(authorization, slack_message)
    |> maybe_find_customer(authorization, slack_message)
    |> case do
      %User{} = user -> user
      %Customer{} = customer -> customer
      _ -> nil
    end
  end

  @doc """
  Updates the params with a "user_id" field if a "customer_id" has not already been set.
  """
  @spec maybe_set_user_id(map(), SlackAuthorization.t(), map()) :: map()
  def maybe_set_user_id(%{"customer_id" => customer_id} = params, _authorization, _event)
      when not is_nil(customer_id),
      do: params

  def maybe_set_user_id(params, authorization, %{"user" => slack_user_id}) do
    case find_matching_user(authorization, slack_user_id) do
      %User{id: user_id} ->
        Map.merge(params, %{"user_id" => user_id})

      _ ->
        params
    end
  end

  def maybe_set_user_id(params, _authorization, _event), do: params

  @doc """
  Updates the params with a "customer_id" field if a "user_id" has not already been set.
  """
  @spec maybe_set_customer_id(map(), SlackAuthorization.t(), map()) :: map()
  def maybe_set_customer_id(%{"user_id" => user_id} = params, _authorization, _event)
      when not is_nil(user_id),
      do: params

  def maybe_set_customer_id(params, authorization, event) do
    case create_or_update_customer_from_slack_event(authorization, event) do
      {:ok, %Customer{id: customer_id}} ->
        Map.merge(params, %{"customer_id" => customer_id})

      _ ->
        params
    end
  end

  @spec format_sender_id_v2!(SlackAuthorization.t(), map()) :: map()
  def format_sender_id_v2!(authorization, event) do
    %{}
    |> maybe_set_user_id(authorization, event)
    |> maybe_set_customer_id(authorization, event)
    |> case do
      params when map_size(params) == 1 ->
        params

      _invalid ->
        raise "Unable to find matching user or customer ID for Slack event #{inspect(event)} on account authorization #{
                inspect(authorization)
              }"
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
            case create_or_update_customer_from_slack_user_id(
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
    conversation = Conversations.get_conversation_with!(conversation_id, [])

    response
    |> Slack.Extractor.extract_slack_conversation_thread_info!()
    |> Map.merge(%{
      conversation_id: conversation_id,
      account_id: conversation.account_id
    })
    |> SlackConversationThreads.create_slack_conversation_thread()
  end

  @spec is_bot_message?(map()) :: boolean()
  def is_bot_message?(%{"bot_id" => bot_id}) when not is_nil(bot_id), do: true
  def is_bot_message?(_), do: false

  @spec is_agent_message?(SlackAuthorization.t(), map()) :: boolean()
  def is_agent_message?(authorization, %{"user" => slack_user_id})
      when not is_nil(slack_user_id) do
    case find_matching_user(authorization, slack_user_id) do
      %User{} -> true
      _ -> false
    end
  end

  def is_agent_message?(_authorization, _), do: false

  @spec is_customer_message?(SlackAuthorization.t(), map()) :: boolean()
  def is_customer_message?(authorization, slack_message) do
    !is_bot_message?(slack_message) && !is_agent_message?(authorization, slack_message)
  end

  @spec sanitize_slack_message(binary(), SlackAuthorization.t()) :: binary()
  def sanitize_slack_message(text, %SlackAuthorization{
        access_token: access_token
      }) do
    text
    |> sanitize_slack_user_ids(access_token)
    |> sanitize_slack_links()
    |> sanitize_slack_mailto_links()
    |> sanitize_private_note()
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

  @private_note_prefix_v1 ~S(\\)
  @private_note_prefix_v2 ~S(;;)
  @private_note_prefix_regex_v1 ~r/^\\\\/
  @private_note_prefix_regex_v2 ~r/^;;/

  @spec sanitize_private_note(binary()) :: binary()
  def sanitize_private_note(text) do
    text
    |> String.replace(@private_note_prefix_regex_v1, "")
    |> String.replace(@private_note_prefix_regex_v2, "")
    |> String.trim()
  end

  @spec parse_message_type_params(binary()) :: map()
  def parse_message_type_params(text) do
    case text do
      @private_note_prefix_v1 <> _note -> %{"private" => true, "type" => "note"}
      @private_note_prefix_v2 <> _note -> %{"private" => true, "type" => "note"}
      _ -> %{}
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

  @spec slack_ts_to_utc(binary() | nil) :: DateTime.t()
  def slack_ts_to_utc(nil), do: DateTime.utc_now()

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
  # Formatters
  #####################

  @spec get_dashboard_conversation_url(binary()) :: binary()
  def get_dashboard_conversation_url(conversation_id) do
    url = System.get_env("BACKEND_URL") || ""

    base =
      if Application.get_env(:chat_api, :environment) == :dev do
        "http://localhost:3000"
      else
        "https://" <> url
      end

    "#{base}/conversations/all?cid=#{conversation_id}"
  end

  @spec format_message_body(Message.t()) :: binary()
  def format_message_body(%Message{body: nil}), do: ""
  def format_message_body(%Message{private: true, type: "note", body: nil}), do: "\\\\ _Note_"
  def format_message_body(%Message{private: true, type: "note", body: body}), do: "\\\\ _#{body}_"

  def format_message_body(%Message{private: true, type: "bot", body: body}),
    do: "\\\\ _ #{body} _"

  # TODO: handle messages that are too long better (rather than just slicing them)
  def format_message_body(%Message{body: body}) do
    case String.length(body) do
      n when n > 2500 -> String.slice(body, 0..2500) <> "..."
      _ -> body
    end
  end

  @spec prepend_sender_prefix(binary(), Message.t()) :: binary()
  def prepend_sender_prefix(text, %Message{} = message) do
    case message do
      %Message{user: %User{} = user} ->
        "*:female-technologist: #{Slack.Notification.format_user_name(user)}*: #{text}"

      %Message{customer: %Customer{} = customer} ->
        "*:wave: #{identify_customer(customer)}*: #{text}"

      %Message{customer_id: nil, user_id: user_id} when not is_nil(user_id) ->
        "*:female-technologist: Agent*: #{text}"

      _ ->
        Logger.error("Unrecognized message format: #{inspect(message)}")

        text
    end
  end

  @spec prepend_sender_prefix(binary(), Message.t(), Conversation.t()) :: binary()
  def prepend_sender_prefix(text, %Message{} = message, %Conversation{} = conversation) do
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

  @spec append_attachments_text(binary() | nil, Message.t()) :: binary()
  def append_attachments_text(text, %Message{attachments: [_ | _] = attachments}) do
    attachments_text =
      attachments
      |> Stream.map(fn file -> "> <#{file.file_url}|#{file.filename}>" end)
      |> Enum.join("\n")

    text <> "\n\n" <> attachments_text
  end

  def append_attachments_text(text, _message), do: text

  @spec get_message_text(map()) :: binary()
  def get_message_text(%{
        conversation: %Conversation{customer: %Customer{}} = conversation,
        message: %Message{} = message,
        authorization: _authorization,
        thread: nil
      }) do
    dashboard_link = "<#{get_dashboard_conversation_url(conversation.id)}|dashboard>"

    formatted_text =
      message
      |> format_message_body()
      |> prepend_sender_prefix(message, conversation)
      |> append_attachments_text(message)

    [
      formatted_text,
      "Reply to this thread to start chatting, or view in the #{dashboard_link} :rocket:",
      "(Start a message with `;;` or `\\\\` to send an <https://github.com/papercups-io/papercups/pull/562|internal note>.)"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  @slack_chat_write_customize_scope "chat:write.customize"

  def get_message_text(%{
        conversation: %Conversation{} = conversation,
        message: %Message{} = message,
        authorization: %SlackAuthorization{} = authorization,
        thread: %SlackConversationThread{}
      }) do
    if SlackAuthorizations.has_authorization_scope?(
         authorization,
         @slack_chat_write_customize_scope
       ) do
      message
      |> format_message_body()
      |> append_attachments_text(message)
    else
      message
      |> format_message_body()
      |> prepend_sender_prefix(message, conversation)
      |> append_attachments_text(message)
    end
  end

  @spec get_message_payload(binary(), map()) :: map()
  def get_message_payload(text, %{
        channel: channel,
        conversation: conversation,
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
      "unfurl_links" => false,
      "unfurl_media" => false,
      "text" => text,
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
            },
            %{
              "type" => "mrkdwn",
              "text" => "*Status:*\n#{get_slack_conversation_status(conversation)}"
            }
          ]
        },
        %{
          "type" => "divider"
        },
        %{
          "type" => "actions",
          "elements" => [
            %{
              "type" => "button",
              "text" => %{
                "type" => "plain_text",
                "text" => "Mark as resolved"
              },
              "value" => conversation.id,
              "action_id" => "close_conversation",
              "style" => "primary"
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

  @spec update_fields_with_conversation_status([map()], Conversation.t()) :: [map()]
  def update_fields_with_conversation_status(fields, conversation) do
    status = get_slack_conversation_status(conversation)

    if Enum.any?(fields, &is_slack_conversation_status_field?/1) do
      Enum.map(fields, fn field ->
        if is_slack_conversation_status_field?(field) do
          Map.merge(field, %{
            "type" => "mrkdwn",
            "text" => "*Status:*\n#{status}"
          })
        else
          field
        end
      end)
    else
      fields ++
        [
          %{
            "type" => "mrkdwn",
            "text" => "*Status:*\n#{status}"
          }
        ]
    end
  end

  @spec update_action_elements_with_conversation_status(Conversation.t()) :: [map()]
  def update_action_elements_with_conversation_status(%Conversation{id: id, status: status}) do
    case status do
      "open" ->
        [
          %{
            "type" => "button",
            "text" => %{
              "type" => "plain_text",
              "text" => "Mark as resolved"
            },
            "value" => id,
            "action_id" => "close_conversation",
            "style" => "primary"
          }
        ]

      "closed" ->
        [
          %{
            "type" => "button",
            "text" => %{
              "type" => "plain_text",
              "text" => "Reopen conversation"
            },
            "value" => id,
            "action_id" => "open_conversation"
          }
        ]
    end
  end

  @spec get_slack_conversation_status(Conversation.t()) :: binary()
  def get_slack_conversation_status(conversation) do
    case conversation do
      %{status: "closed"} ->
        ":white_check_mark: Closed"

      %{closed_at: closed_at} when not is_nil(closed_at) ->
        ":white_check_mark: Closed"

      %{status: "open", first_replied_at: nil} ->
        ":wave: Unhandled"

      %{status: "open", first_replied_at: first_replied_at} when not is_nil(first_replied_at) ->
        ":speech_balloon: In progress"
    end
  end

  @spec is_slack_conversation_status_field?(map()) :: boolean()
  def is_slack_conversation_status_field?(%{"text" => text} = _field) do
    text =~ "*Status:*" || text =~ "*Conversation status:*" || text =~ "*Conversation Status:*"
  end

  def is_slack_conversation_status_field?(_field), do: false

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
