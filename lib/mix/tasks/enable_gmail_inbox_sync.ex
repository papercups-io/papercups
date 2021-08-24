defmodule Mix.Tasks.EnableGmailInboxSync do
  use Mix.Task

  @shortdoc "Script to enable the Gmail inbox sync feature for the given account"

  @moduledoc """
  Example:
  ```
  $ mix enable_gmail_inbox_sync [ACCOUNT_ID]
  $ mix enable_gmail_inbox_sync [ACCOUNT_ID] [HISTORY_ID]
  ```

  On Heroku:
  ```
  $ heroku run "POOL_SIZE=2 mix enable_gmail_inbox_sync"
  $ heroku run "POOL_SIZE=2 mix enable_gmail_inbox_sync [ACCOUNT_TOKEN]"
  ```
  """

  require Logger

  alias ChatApi.Google
  alias ChatApi.Google.{Gmail, GoogleAuthorization}

  @spec run([binary()]) :: :ok
  def run(args) do
    Application.ensure_all_started(:chat_api)

    result =
      case args do
        [account_id] ->
          enable_gmail_sync(account_id)

        [account_id, history_id] ->
          enable_gmail_sync(account_id, history_id)

        _ ->
          {:error, "An account ID is required as the initial arg"}
      end

    case result do
      {:ok, authorization} ->
        Logger.info(
          "Successfully updated authorization metadata for account #{
            inspect(authorization.account_id)
          }: #{inspect(authorization.metadata)}"
        )

      {:error, reason} ->
        Logger.error("Failed to enable account: #{inspect(reason)}")
    end
  end

  @spec enable_gmail_sync(binary(), binary()) ::
          {:error, binary() | Ecto.Changeset.t()}
          | {:ok, ChatApi.Google.GoogleAuthorization.t()}
  def enable_gmail_sync(account_id, history_id) do
    case Google.get_authorization_by_account(account_id, %{client: "gmail", type: "support"}) do
      %GoogleAuthorization{} = authorization ->
        Google.update_google_authorization(authorization, %{
          metadata: %{next_history_id: history_id}
        })

      _ ->
        {:error, "Gmail authorization not found for account"}
    end
  end

  @spec enable_gmail_sync(binary()) ::
          {:error, binary() | Ecto.Changeset.t()}
          | {:ok, ChatApi.Google.GoogleAuthorization.t()}
  def enable_gmail_sync(account_id) do
    case Google.get_authorization_by_account(account_id, %{client: "gmail", type: "support"}) do
      %GoogleAuthorization{refresh_token: token} = authorization ->
        history_id =
          token
          |> Gmail.list_threads()
          |> Map.get("threads", [])
          |> List.first()
          |> Map.get("historyId")

        case Gmail.list_history(token, start_history_id: history_id) do
          %{"historyId" => next_history_id} ->
            Google.update_google_authorization(authorization, %{
              metadata: %{next_history_id: next_history_id}
            })

          _ ->
            {:error, "Unable to find valid history ID"}
        end

      authorization ->
        {:error, "Invalid authorization #{inspect(authorization)}"}
    end
  end
end
