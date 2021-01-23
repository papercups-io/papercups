defmodule ChatApi.WidgetSettings.WidgetSetting do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          title: String.t() | nil,
          subtitle: String.t() | nil,
          color: String.t() | nil,
          greeting: String.t() | nil,
          new_message_placeholder: String.t() | nil,
          base_url: String.t() | nil,
          host: String.t() | nil,
          pathname: String.t() | nil,
          last_seen_at: DateTime.t() | nil,
          # Foreign keys
          account_id: Ecto.UUID.t(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "widget_settings" do
    field :title, :string
    field :subtitle, :string
    field :color, :string
    field :greeting, :string
    field :new_message_placeholder, :string
    field :base_url, :string

    field :host, :string
    field :pathname, :string
    field :last_seen_at, :utc_datetime

    belongs_to(:account, Account)

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
      :base_url,
      :account_id,
      :host,
      :pathname,
      :last_seen_at
    ])
    |> validate_required([:account_id])
    |> unique_constraint(:account_id)
    |> foreign_key_constraint(:account_id)
  end
end
