defmodule Mix.Tasks.FixSlackMessageFormatting do
  use Mix.Task

  require Logger
  import Ecto.Query, warn: false
  alias ChatApi.{Messages, Repo, Slack, SlackAuthorizations}
  alias ChatApi.Messages.Message
  alias ChatApi.SlackAuthorizations.SlackAuthorization

  @shortdoc "Fixes Slack message formatting for links and user IDs."

  @moduledoc """
  This task handles fixing Slack message formatting. For example, Slack has its own
  markup for URLs and mailto links, which we want to convert to conventional markdown.
  Slack also sends raw user IDs, which we want to convert to the user's display name.

  Example:
  ```
  $ mix fix_slack_message_formatting
  $ mix fix_slack_message_formatting [ACCOUNT_TOKEN]
  ```

  On Heroku:
  ```
  $ heroku run "POOL_SIZE=2 mix fix_slack_message_formatting"
  $ heroku run "POOL_SIZE=2 mix fix_slack_message_formatting [ACCOUNT_TOKEN]"
  ```

  """

  @spec run([binary()]) :: :ok
  def run(args) do
    Application.ensure_all_started(:chat_api)

    Message
    |> where([m], ilike(m.body, "%<@U%"))
    |> filter_args(args)
    |> Repo.all()
    |> Enum.each(fn %Message{account_id: account_id, body: body} = message ->
      case find_valid_slack_authorization(account_id) do
        %SlackAuthorization{} = authorization ->
          Messages.update_message(message, %{
            body: Slack.Helpers.sanitize_slack_message(body, authorization),
            metadata: Slack.Helpers.get_slack_message_metadata(body)
          })

        _ ->
          nil
      end
    end)
  end

  @spec find_valid_slack_authorization(binary()) :: SlackAuthorization.t() | nil
  def find_valid_slack_authorization(account_id) do
    account_id
    |> SlackAuthorizations.list_slack_authorizations_by_account()
    |> Enum.find(fn auth ->
      String.contains?(auth.scope, "users:read") &&
        String.contains?(auth.scope, "users:read.email")
    end)
  end

  @spec filter_args(Ecto.Query.t(), [binary()] | []) :: Ecto.Query.t()
  def filter_args(query, []), do: query

  def filter_args(query, [account_id]) do
    query |> where(account_id: ^account_id)
  end

  def filter_args(query, _), do: query
end
