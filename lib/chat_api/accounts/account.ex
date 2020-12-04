defmodule ChatApi.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.WorkingHours
  alias ChatApi.Customers.Customer
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User
  alias ChatApi.WidgetSettings.WidgetSetting

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field(:company_name, :string)
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

    embeds_many(:working_hours, WorkingHours, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :company_name,
      :time_zone
    ])
    |> cast_embed(:working_hours, with: &working_hours_changeset/2)
    |> validate_required([:company_name])
  end

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

  defp working_hours_changeset(schema, params) do
    schema
    |> cast(params, [:day, :start_minute, :end_minute])
  end
end
