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
  ```

  On Heroku:
  ```
  $ heroku run "POOL_SIZE=2 mix send_ad_hoc_notifications hello"
  $ heroku run "POOL_SIZE=2 mix send_ad_hoc_notifications hello b3e8e400-125d-495d-bb76-2ae75aaa9ed6"
  ```
  """

  def run([]) do
    # TODO: set up more helpful error message
    Logger.error("Please include the message you would like to send out!")
  end

  def run([text | args]) do
    Application.ensure_all_started(:chat_api)

    {:ok, message} = parse(text)

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
        |> Enum.each(&notify(message, &1))
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

  def parse(text) do
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

  def already_sent_message?(text, account_id: account_id, customer_id: customer_id) do
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

    Repo.one(query) > 0
  end

  def notify(text, account_id) do
    with %{company_name: company_name} <- Accounts.get_account!(account_id),
         # TODO: use founders@
         {:ok, customer} <-
           Customers.find_or_create_by_email("alex@papercups.io", account_id, %{
             name: "Papercups Team",
             profile_photo_url:
               "https://avatars.slack-edge.com/2021-01-13/1619416452487_002cddd7d8aea1950018_192.png"
           }),
         false <- already_sent_message?(text, account_id: account_id, customer_id: customer.id),
         :ok <- Logger.info("Sending to #{company_name}: #{text}"),
         {:ok, conversation} <-
           Conversations.find_or_create_by_customer(account_id, customer.id),
         {:ok, message} <-
           Messages.create_message(%{
             source: "api",
             account_id: account_id,
             conversation_id: conversation.id,
             customer_id: customer.id,
             body: text
           }) do
      # TODO: only do this if conversation is actually new? (or just create new conversation for each message)
      conversation
      |> Conversations.Notification.broadcast_new_conversation_to_admin!()

      message.id
      |> Messages.get_message!()
      |> Messages.Notification.broadcast_to_customer!()
      |> Messages.Notification.broadcast_to_admin!()
      |> Messages.Notification.notify(:slack, async: false)
      |> Messages.Notification.notify(:mattermost, async: false)
      |> Messages.Notification.notify(:new_message_email, async: false)
    end
  end
end
