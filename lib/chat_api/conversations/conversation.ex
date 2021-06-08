defmodule ChatApi.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{
    Accounts.Account,
    Customers.Customer,
    Issues.ConversationIssue,
    Messages.Message,
    Tags.ConversationTag,
    Users.User
  }

  @type t :: %__MODULE__{
          status: String.t(),
          priority: String.t(),
          source: String.t() | nil,
          subject: String.t() | nil,
          read: boolean(),
          archived_at: any(),
          closed_at: any(),
          last_activity_at: any(),
          metadata: any(),
          # Relations
          assignee_id: any(),
          assignee: any(),
          account_id: any(),
          account: any(),
          customer_id: any(),
          customer: any(),
          messages: any(),
          conversation_tags: any(),
          tags: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field(:status, :string, default: "open")
    field(:priority, :string, default: "not_priority")
    field(:source, :string, default: "chat")
    field(:subject, :string)
    field(:read, :boolean, default: false)
    field(:archived_at, :utc_datetime)
    field(:first_replied_at, :utc_datetime)
    field(:closed_at, :utc_datetime)
    field(:last_activity_at, :utc_datetime)
    field(:metadata, :map)

    has_many(:messages, Message)
    belongs_to(:assignee, User, foreign_key: :assignee_id, references: :id, type: :integer)
    belongs_to(:account, Account)
    belongs_to(:customer, Customer)

    has_many(:conversation_tags, ConversationTag)
    has_many(:tags, through: [:conversation_tags, :tag])
    has_many(:conversation_issues, ConversationIssue)
    has_many(:issues, through: [:conversation_issues, :issue])

    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :status,
      :priority,
      :read,
      :assignee_id,
      :account_id,
      :customer_id,
      :archived_at,
      :first_replied_at,
      :closed_at,
      :source,
      :subject,
      :metadata
    ])
    |> validate_required([:status, :account_id, :customer_id])
    |> validate_inclusion(:source, ["chat", "slack", "email", "sms", "api", "sandbox"])
    |> put_closed_and_last_activity_at()
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:customer_id)
  end

  def last_activity_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:last_activity_at])
  end

  defp put_closed_and_last_activity_at(
         %Ecto.Changeset{valid?: true, changes: %{status: status}} = changeset
       ) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case status do
      "closed" ->
        changeset
        |> put_change(:last_activity_at, now)
        |> put_change(:closed_at, now)

      "open" ->
        changeset
        |> put_change(:last_activity_at, now)
        |> put_change(:closed_at, nil)
    end
  end

  defp put_closed_and_last_activity_at(changeset), do: changeset
end
