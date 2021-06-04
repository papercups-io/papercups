defmodule ChatApi.Workers.SyncGmailInboxes do
  use Oban.Worker, queue: :default

  require Logger

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{} = job) do
    Logger.debug("Syncing Gmail inboxes: #{inspect(job)}")

    %{client: "gmail"}
    |> ChatApi.Google.list_google_authorizations()
    |> Enum.each(fn authorization ->
      %{account_id: authorization.account_id}
      |> ChatApi.Workers.SyncGmailInbox.new()
      |> Oban.insert()
    end)

    :ok
  end
end
