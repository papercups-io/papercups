defmodule ChatApi.Issues.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User
  alias ChatApi.Issues.{ConversationIssue, CustomerIssue}

  @type t :: %__MODULE__{
          title: String.t(),
          body: String.t() | nil,
          state: String.t(),
          github_issue_url: String.t() | nil,
          finished_at: DateTime.t() | nil,
          closed_at: DateTime.t() | nil,
          metadata: map() | nil,
          # Relations
          account_id: any(),
          account: any(),
          creator_id: any(),
          creator: any(),
          assignee_id: any(),
          assignee: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "issues" do
    field(:title, :string)
    field(:body, :string)
    field(:state, :string, default: "unstarted")
    field(:finished_at, :utc_datetime)
    field(:closed_at, :utc_datetime)
    field(:github_issue_url, :string)
    field(:metadata, :map)

    belongs_to(:account, Account)
    belongs_to(:creator, User, foreign_key: :creator_id, references: :id, type: :integer)
    belongs_to(:assignee, User, foreign_key: :assignee_id, references: :id, type: :integer)

    has_many(:conversation_issues, ConversationIssue)
    has_many(:conversations, through: [:conversation_issues, :conversation])
    has_many(:customer_issues, CustomerIssue)
    has_many(:customers, through: [:customer_issues, :customer])

    timestamps()
  end

  @doc false
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [
      :title,
      :body,
      :state,
      :github_issue_url,
      :finished_at,
      :closed_at,
      :account_id,
      :creator_id,
      :assignee_id
    ])
    |> validate_required([:title, :state, :account_id])
    |> validate_inclusion(:state, [
      "unstarted",
      "in_progress",
      "in_review",
      "done",
      "closed"
    ])
  end
end
