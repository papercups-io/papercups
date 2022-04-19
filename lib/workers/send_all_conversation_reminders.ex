defmodule ChatApi.Workers.SendAllConversationReminders do
  use Oban.Worker, queue: :default

  import Ecto.Query, warn: false

  alias ChatApi.Repo
  alias ChatApi.Accounts.Account

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("Initializing conversation reminders...")

    Account
    |> where([_q], fragment("(settings->>'conversation_reminders_enabled' = 'true')"))
    |> Repo.all()
    |> Enum.each(fn account ->
      %{"account_id" => account.id}
      |> ChatApi.Workers.SendAccountConversationReminders.new()
      |> Oban.insert()
    end)

    :ok
  end
end
