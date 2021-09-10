defmodule ChatApi.Workers.SyncGmailInboxes do
  use Oban.Worker, queue: :default
  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.Repo

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{} = job) do
    Logger.debug("Syncing Gmail inboxes: #{inspect(job)}")

    account_ids = list_authorized_account_ids()
    cancel_pending_jobs(account_ids)
    enqueue_new_jobs(account_ids)

    :ok
  end

  @spec enqueue_new_jobs([binary()]) :: :ok
  def enqueue_new_jobs(account_ids) do
    Enum.each(account_ids, fn account_id ->
      %{account_id: account_id}
      |> ChatApi.Workers.SyncGmailInbox.new()
      |> Oban.insert()
    end)
  end

  @spec cancel_pending_jobs([binary()]) :: :ok
  def cancel_pending_jobs(account_ids) do
    ids = Enum.join(account_ids, ", ")

    Oban.Job
    |> where(worker: "ChatApi.Workers.SyncGmailInbox")
    |> where([j], j.state in ["available", "scheduled" or "retryable"])
    |> where([_j], fragment("(args->>'account_id' in (?))", ^ids))
    |> Repo.all()
    |> Enum.each(fn job -> Oban.cancel_job(job.id) end)
  end

  @spec list_authorized_account_ids() :: [binary()]
  def list_authorized_account_ids() do
    %{client: "gmail"}
    |> ChatApi.Google.list_google_authorizations()
    |> Enum.map(& &1.account_id)
  end
end
