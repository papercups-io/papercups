defmodule ChatApi.WidgetConfigs.WidgetConfig do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "widget_configs" do
    field :color, :string
    field :subtitle, :string
    field :title, :string
    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(widget_config, attrs) do
    widget_config
    |> cast(attrs, [:title, :subtitle, :color, :account_id])
    |> validate_required([:title, :subtitle, :color, :account_id])
    |> unique_constraint(:account_id)
  end
end
