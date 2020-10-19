defmodule ChatApi.Workers.SaveBrowserReplayEvent do
  @moduledoc false

  use Oban.Worker, queue: :events

  require Logger

  @admin_account_id System.get_env("REACT_APP_ADMIN_ACCOUNT_ID")

  @impl Oban.Worker
  def perform(%Oban.Job{args: params}) do
    # Only save for admin account ID for now
    if params["account_id"] == @admin_account_id do
      ChatApi.BrowserReplayEvents.create_browser_replay_event(params)
    else
      :ok
    end
  end
end
