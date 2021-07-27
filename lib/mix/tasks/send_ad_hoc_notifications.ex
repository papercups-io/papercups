defmodule Mix.Tasks.SendAdHocNotifications do
  use Mix.Task
  require Logger
  import Ecto.Query, warn: false

  alias ChatApi.{
    Accounts,
    Conversations,
    Customers,
    Messages,
    Repo
  }

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message

  @shortdoc "Send ad hoc notifications to existing users"

  @moduledoc """
  This task syncs latest user data with customer.io

  Example:
  ```
  $ mix send_ad_hoc_notifications "this is a message that will be sent to all active accounts"
  $ mix send_ad_hoc_notifications https://gist.github.com/some_markdown_file.md
  $ mix send_ad_hoc_notifications https://gist.github.com/some_text_file.txt
  $ mix send_ad_hoc_notifications hello b3e8e400-125d-495d-bb76-2ae75aaa9ed6
  $ mix send_ad_hoc_notifications hello --dry_run
  $ mix send_ad_hoc_notifications hello --dry_run=true
  ```

  On Heroku:
  ```
  $ heroku run "POOL_SIZE=2 mix send_ad_hoc_notifications hello"
  $ heroku run "POOL_SIZE=2 mix send_ad_hoc_notifications hello b3e8e400-125d-495d-bb76-2ae75aaa9ed6"
  ```
  """

  # TODO: use founders@
  @papercups_email "alex@papercups.io"

  def run([]) do
    # TODO: set up more helpful error message
    Logger.error("Please include the message you would like to send out!")
  end

  def run([text | args]) do
    # TODO: make it possible to do dry runs!
    Application.ensure_all_started(:chat_api)

    {:ok, message} = parse_input(text)

    opts = parse_opts(args)
    args = Enum.reject(args, &String.starts_with?(&1, "--"))

    account_ids =
      case args do
        [] ->
          account_ids_active_after(ago: [3, "month"])

        account_ids ->
          account_ids
      end

    case account_ids do
      [] ->
        Logger.info("No accounts found - skipping notification!")

      [_ | _] ->
        account_ids
        |> Enum.uniq()
        |> Enum.each(&notify(message, &1, opts))
    end
  end

  def is_valid_url?(str) do
    case URI.parse(str) do
      %{scheme: nil, host: nil} ->
        false

      %{scheme: scheme, path: path} ->
        has_valid_scheme = scheme == "https" || scheme == "http"
        has_valid_ext = String.ends_with?(path, ".md") || String.ends_with?(path, ".txt")

        has_valid_scheme && has_valid_ext

      _ ->
        false
    end
  end

  def parse_opts(args) do
    args
    |> Enum.filter(&String.starts_with?(&1, "--"))
    |> Map.new(fn opt ->
      [key, value] =
        case String.split(opt, "=") do
          [k] -> [k, "true"]
          [k, v] -> [k, v]
        end

      k = key |> String.replace("--", "") |> String.to_atom()

      v =
        case value do
          "true" -> true
          "false" -> false
          str -> str
        end

      {k, v}
    end)
    |> Map.to_list()
  end

  def parse_input(text) do
    # TODO: add support for templates?
    if is_valid_url?(text) do
      case Tesla.get(text) do
        {:ok, %{body: body}} -> {:ok, body}
        error -> error
      end
    else
      {:ok, text}
    end
  end

  def account_ids_active_after(ago: [n, unit]) do
    query =
      from(m in Message,
        distinct: m.account_id,
        where: m.inserted_at > ago(^n, ^unit),
        select: m.account_id
      )

    Repo.all(query)
  end

  def validate(text, account_id: account_id, customer_id: customer_id) do
    query =
      from(m in Message,
        join: c in Conversation,
        on: m.conversation_id == c.id,
        where:
          m.account_id == ^account_id and
            m.customer_id == ^customer_id and
            m.body == ^text and
            is_nil(c.archived_at),
        select: count("*")
      )

    if Repo.one(query) > 0 do
      {:error, :message_already_sent}
    else
      :ok
    end
  end

  def notify(text, account_id, dry_run: true) do
    with %{company_name: company_name} <- Accounts.get_account!(account_id),
         %Customer{id: customer_id} <- Customers.find_by_email(@papercups_email, account_id),
         :ok <- validate(text, account_id: account_id, customer_id: customer_id) do
      Logger.info("[--dry_run] Would have sent to #{company_name}: #{inspect(text)}")
    else
      error -> Logger.info("Skipped sending message to account #{account_id}: #{inspect(error)}")
    end
  end

  def notify(text, account_id, _opts) do
    with %{company_name: company_name} <- Accounts.get_account!(account_id),
         {:ok, customer} <-
           Customers.find_or_create_by_email(@papercups_email, account_id, %{
             name: "Papercups Team",
             profile_photo_url:
               "https://avatars.slack-edge.com/2021-01-13/1619416452487_002cddd7d8aea1950018_192.png"
           }),
         :ok <- validate(text, account_id: account_id, customer_id: customer.id),
         :ok <- Logger.info("Sending to #{company_name}: #{text}"),
         {:ok, conversation} <-
           Conversations.create_conversation(%{account_id: account_id, customer_id: customer.id}),
         {:ok, message} <-
           Messages.create_message(%{
             source: "api",
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             body: text
           }) do
      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()

      message.id
      |> Messages.get_message!()
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:slack, async: false)
      |> Messages.Notification.notify(:mattermost, async: false)
      |> Messages.Notification.notify(:new_message_email, async: false)
    else
      error -> Logger.info("Skipped sending message to account #{account_id}: #{inspect(error)}")
    end
  end
end
