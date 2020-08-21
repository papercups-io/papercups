defmodule ChatApi.Workers.Example do
  use Oban.Worker, queue: :events

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    IO.puts("Performing job!")
    IO.inspect(job)

    :ok
  end
end
