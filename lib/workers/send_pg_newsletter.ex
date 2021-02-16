defmodule ChatApi.Workers.SendPgNewsletter do
  @moduledoc """
  A worker that sends a daily PG essay newsletter
  """

  use Oban.Worker, queue: :default

  require Logger

  alias ChatApi.Newsletters

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    Logger.info("Attempting to send PG newsletter")

    try do
      Newsletters.Pg.run!()
    rescue
      e -> Logger.error("Failed to send PG newsletter: #{inspect(e)}")
    end

    :ok
  end
end
