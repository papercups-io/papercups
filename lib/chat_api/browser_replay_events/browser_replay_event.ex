defmodule ChatApi.BrowserReplayEvents.BrowserReplayEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.BrowserSessions.BrowserSession

  @type t :: %__MODULE__{
          event: any(),
          timestamp: any(),
          # Relations
          account_id: any(),
          account: any(),
          browser_session_id: any(),
          browser_session: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "browser_replay_events" do
    field(:event, :map)
    field(:timestamp, :utc_datetime_usec)

    belongs_to(:account, Account)
    belongs_to(:browser_session, BrowserSession)

    timestamps()
  end

  @doc false
  def changeset(browser_replay_event, attrs) do
    browser_replay_event
    |> cast(attrs, [:account_id, :browser_session_id, :event, :timestamp])
    |> validate_required([:account_id, :browser_session_id, :event])
  end
end
