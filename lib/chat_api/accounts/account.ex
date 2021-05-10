defmodule ChatApi.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.{Settings, WorkingHours}
  alias ChatApi.Customers.Customer
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User
  alias ChatApi.WidgetSettings.WidgetSetting
  alias ChatApi.CannedResponses.CannedResponse

  @type t :: %__MODULE__{
          company_name: String.t(),
          company_logo_url: String.t() | nil,
          time_zone: String.t() | nil,
          subscription_plan: String.t() | nil,
          # Stripe fields
          stripe_customer_id: String.t() | nil,
          stripe_subscription_id: String.t() | nil,
          stripe_product_id: String.t() | nil,
          stripe_default_payment_method_id: String.t() | nil,
          # Relations
          customers: any(),
          conversations: any(),
          messages: any(),
          users: any(),
          widget_settings: any(),
          canned_responses: any(),
          working_hours: any(),
          settings: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:company_name, :string)
    field(:company_logo_url, :string)
    field(:time_zone, :string)
    field(:subscription_plan, :string, default: "starter")

    field(:stripe_customer_id, :string)
    field(:stripe_subscription_id, :string)
    field(:stripe_product_id, :string)
    field(:stripe_default_payment_method_id, :string)

    has_many(:customers, Customer)
    has_many(:conversations, Conversation)
    has_many(:messages, Message)
    has_many(:users, User)
    has_one(:widget_settings, WidgetSetting)
    has_many(:canned_responses, CannedResponse)

    embeds_one(:settings, Settings, on_replace: :delete)
    embeds_many(:working_hours, WorkingHours, on_replace: :delete)

    timestamps()
  end

  @doc false
  @spec changeset(any(), map()) :: Ecto.Changeset.t()
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :company_name,
      :company_logo_url,
      :time_zone
    ])
    |> cast_embed(:working_hours, with: &working_hours_changeset/2)
    |> cast_embed(:settings, with: &account_settings_changeset/2)
    |> validate_required([:company_name])
  end

  @spec billing_details_changeset(any(), map()) :: Ecto.Changeset.t()
  def billing_details_changeset(account, attrs) do
    account
    |> cast(attrs, [
      :subscription_plan,
      :stripe_customer_id,
      :stripe_subscription_id,
      :stripe_product_id,
      :stripe_default_payment_method_id
    ])
    |> validate_required([:subscription_plan])
  end

  @spec working_hours_changeset(any(), map()) :: Ecto.Changeset.t()
  defp working_hours_changeset(schema, params) do
    schema
    |> cast(params, [:day, :start_minute, :end_minute])
  end

  @spec account_settings_changeset(any(), map()) :: Ecto.Changeset.t()
  def account_settings_changeset(schema, params) do
    schema
    |> cast(params, [
      :disable_automated_reply_emails,
      :conversation_reminders_enabled,
      :conversation_reminder_hours_interval,
      :max_num_conversation_reminders
    ])
  end
end
