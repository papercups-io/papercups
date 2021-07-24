defmodule Mix.Tasks.SendAdHocNotifications do
  use Mix.Task
  require Logger
  import Ecto.Query, warn: false

  alias ChatApi.Repo
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

  def notify(text, account_id) do
    %{text: text, account_id: account_id}
    |> ChatApi.Workers.SendAdHocNotification.new()
    |> Oban.insert()
  end
end
