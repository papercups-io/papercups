defmodule ChatApi.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{
    Accounts.Account,
    Companies.Company,
    Conversations.Conversation,
    Issues.CustomerIssue,
    Messages.Message,
    Notes.Note,
    Tags.CustomerTag
  }

  @type t :: %__MODULE__{
          first_seen: any(),
          email: String.t() | nil,
          name: String.t() | nil,
          phone: String.t() | nil,
          external_id: String.t() | nil,
          profile_photo_url: String.t() | nil,
          # Browser metadata
          browser: String.t() | nil,
          browser_version: String.t() | nil,
          browser_language: String.t() | nil,
          os: String.t() | nil,
          ip: String.t() | nil,
          last_seen_at: any(),
          current_url: String.t() | nil,
          host: String.t() | nil,
          pathname: String.t() | nil,
          screen_height: integer() | nil,
          screen_width: integer() | nil,
          lib: String.t() | nil,
          time_zone: String.t() | nil,
          metadata: any(),
          # Relations
          account_id: any(),
          account: any(),
          company_id: any(),
          company: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customers" do
    field(:first_seen, :date)
    field(:email, :string)
    field(:name, :string)
    field(:phone, :string)
    field(:external_id, :string)
    field(:profile_photo_url, :string)

    # Metadata
    field(:browser, :string)
    field(:browser_version, :string)
    field(:browser_language, :string)
    field(:os, :string)
    field(:ip, :string)
    field(:last_seen_at, :utc_datetime)
    field(:current_url, :string)
    field(:host, :string)
    field(:pathname, :string)
    field(:screen_height, :integer)
    field(:screen_width, :integer)
    field(:lib, :string)
    field(:time_zone, :string)

    # Freeform
    field(:metadata, :map)

    has_many(:messages, Message)
    has_many(:conversations, Conversation)
    has_many(:notes, Note)
    belongs_to(:account, Account)
    belongs_to(:company, Company)

    has_many(:customer_tags, CustomerTag)
    has_many(:tags, through: [:customer_tags, :tag])
    has_many(:customer_issues, CustomerIssue)
    has_many(:issues, through: [:customer_issues, :issue])

    timestamps()
  end

  @doc false
  @spec changeset(any(), map()) :: Ecto.Changeset.t()
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :first_seen,
      :account_id,
      :company_id,
      :email,
      :name,
      :phone,
      :external_id,
      :profile_photo_url,
      :browser,
      :browser_version,
      :browser_language,
      :os,
      :ip,
      :last_seen_at,
      :current_url,
      :host,
      :pathname,
      :screen_height,
      :screen_width,
      :lib,
      :time_zone
    ])
    |> validate_required([:first_seen, :last_seen_at, :account_id])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:company_id)
  end

  def metadata_changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :metadata,
      :email,
      :name,
      :phone,
      :external_id,
      :browser,
      :browser_version,
      :browser_language,
      :os,
      :ip,
      :last_seen_at,
      :current_url,
      :host,
      :pathname,
      :screen_height,
      :screen_width,
      :lib,
      :time_zone
    ])
  end
end
