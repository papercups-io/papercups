defmodule ChatApi.Workers.EnableGmailInboxSync do
  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Google
  alias ChatApi.Google.{Gmail, GoogleAuthorization}

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"account_id" => account_id}} = job) do
    Logger.info("Performing job: #{inspect(job)}")

    case enable_gmail_sync(account_id) do
      {:ok, authorization} ->
        Logger.info(
          "Successfully enabled Gmail syncing for account #{inspect(account_id)} with authorization #{
            inspect(authorization.id)
          }"
        )

      {:error, reason} ->
        Logger.error(
          "Failed to enable Gmail syncing for account #{inspect(account_id)}: #{inspect(reason)}"
        )
    end

    :ok
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
