defmodule ChatApi.Workers.SaveBrowserReplayEvent do
  @moduledoc false

  use Oban.Worker, queue: :events

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: params}) do
    ChatApi.BrowserReplayEvents.create_browser_replay_event(params)
  end
end
