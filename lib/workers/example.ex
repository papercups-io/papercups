defmodule ChatApi.Workers.Example do
  use Oban.Worker, queue: :events

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Logger.info("Performing job: #{inspect(job)}")

    :ok
  end
end
