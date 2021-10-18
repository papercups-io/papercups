defmodule ChatApi.Workers.SyncGmailInboxes do
  use Oban.Worker, queue: :default
  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.Repo
  alias ChatApi.Google.GoogleAuthorization

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{} = job) do
    if enabled?() do
      Logger.debug("Syncing Gmail inboxes: #{inspect(job)}")

      authorizations =
        ChatApi.Google.list_google_authorizations(%{
          client: "gmail",
          type: "support"
        })

      cancel_pending_jobs(authorizations)
      enqueue_new_jobs(authorizations)
    else
      Logger.debug("Gmail inbox sync disabled. Skipping: #{inspect(job)}")
    end

    :ok
  end

  @spec enqueue_new_jobs([GoogleAuthorization.t()]) :: :ok
  def enqueue_new_jobs(authorizations) do
    Enum.each(authorizations, fn %GoogleAuthorization{
                                   id: authorization_id,
                                   account_id: account_id
                                 } ->
      %{
        account_id: account_id,
        authorization_id: authorization_id
      }
      |> ChatApi.Workers.SyncGmailInbox.new()
      |> Oban.insert()
    end)
  end

  @spec cancel_pending_jobs([GoogleAuthorization.t()]) :: :ok
  def cancel_pending_jobs(authorizations) do
    account_ids = authorizations |> Enum.map(& &1.account_id) |> Enum.join(", ")

    Oban.Job
    |> where(worker: "ChatApi.Workers.SyncGmailInbox")
    |> where([j], j.state in ["available", "scheduled", "retryable"])
    |> where([_j], fragment("(args->>'account_id' in (?))", ^account_ids))
    |> Repo.all()
    |> Enum.each(fn job -> Oban.cancel_job(job.id) end)
  end

  @spec list_authorized_account_ids() :: [binary()]
  def list_authorized_account_ids() do
    %{client: "gmail", type: "support"}
    |> ChatApi.Google.list_google_authorizations()
    |> Enum.map(& &1.account_id)
  end

  @spec enabled? :: boolean()
  def enabled?() do
    case System.get_env("PAPERCUPS_GMAIL_SYNC_DISABLED") do
      x when x == "1" or x == "true" -> false
      _ -> true
    end
  end
end
