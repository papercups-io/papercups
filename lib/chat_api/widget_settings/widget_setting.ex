defmodule ChatApi.WidgetSettings.WidgetSetting do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Inboxes.Inbox

  @type t :: %__MODULE__{
          title: String.t() | nil,
          subtitle: String.t() | nil,
          color: String.t() | nil,
          greeting: String.t() | nil,
          new_message_placeholder: String.t() | nil,
          show_agent_availability: boolean() | nil,
          agent_available_text: String.t() | nil,
          agent_unavailable_text: String.t() | nil,
          require_email_upfront: boolean() | nil,
          is_open_by_default: boolean() | nil,
          is_branding_hidden: boolean() | nil,
          custom_icon_url: String.t() | nil,
          iframe_url_override: String.t() | nil,
          icon_variant: String.t() | nil,
          email_input_placeholder: String.t() | nil,
          new_messages_notification_text: String.t() | nil,
          base_url: String.t() | nil,
          host: String.t() | nil,
          pathname: String.t() | nil,
          last_seen_at: DateTime.t() | nil,
          away_message: String.t() | nil,
          # Foreign keys
          account_id: Ecto.UUID.t(),
          inbox_id: Ecto.UUID.t(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "widget_settings" do
    field(:title, :string)
    field(:subtitle, :string)
    field(:color, :string)
    field(:greeting, :string)
    field(:new_message_placeholder, :string)
    field(:show_agent_availability, :boolean)
    field(:agent_available_text, :string)
    field(:agent_unavailable_text, :string)
    field(:require_email_upfront, :boolean)
    field(:is_open_by_default, :boolean, default: false)
    field(:is_branding_hidden, :boolean, default: false)
    field(:custom_icon_url, :string)
    field(:iframe_url_override, :string)
    field(:icon_variant, :string, default: "outlined")
    field(:email_input_placeholder, :string)
    field(:new_messages_notification_text, :string)
    field(:base_url, :string)
    field(:away_message, :string)

    field(:host, :string)
    field(:pathname, :string)
    field(:last_seen_at, :utc_datetime)

    belongs_to(:account, Account)
    belongs_to(:inbox, Inbox)

    timestamps()
  end

  @doc false
  def changeset(widget_settings, attrs) do
    widget_settings
    |> cast(attrs, [
      :title,
      :subtitle,
      :color,
      :greeting,
      :new_message_placeholder,
      :show_agent_availability,
      :agent_available_text,
      :agent_unavailable_text,
      :require_email_upfront,
      :is_open_by_default,
      :is_branding_hidden,
      :custom_icon_url,
      :iframe_url_override,
      :icon_variant,
      :email_input_placeholder,
      :new_messages_notification_text,
      :base_url,
      :account_id,
      :inbox_id,
      :host,
      :pathname,
      :last_seen_at,
      :away_message
    ])
    |> validate_required([:account_id])
    |> unique_constraint(:account_id)
    |> foreign_key_constraint(:account_id)
  end
end
