defmodule ChatApi.BrowserSessions.BrowserSession do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.BrowserReplayEvents.BrowserReplayEvent
  alias ChatApi.Customers.Customer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "browser_sessions" do
    field(:finished_at, :utc_datetime)
    # This might just be the same as `inserted_at`?
    field(:started_at, :utc_datetime)

    field(:metadata, :map)

    belongs_to(:account, Account)
    belongs_to(:customer, Customer)
    has_many(:browser_replay_events, BrowserReplayEvent)

    timestamps()
  end

  @doc false
  def changeset(browser_session, attrs) do
    browser_session
    |> cast(attrs, [:account_id, :customer_id, :metadata, :started_at, :finished_at])
    |> validate_required([:account_id])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:customer_id)
  end
end
