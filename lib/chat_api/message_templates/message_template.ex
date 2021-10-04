defmodule ChatApi.MessageTemplates.MessageTemplate do
  use Ecto.Schema
  import Ecto.Changeset
  alias ChatApi.Accounts.Account

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          type: String.t() | nil,
          plain_text: String.t() | nil,
          markdown: String.t() | nil,
          raw_html: String.t() | nil,
          react_js: String.t() | nil,
          react_markdown: String.t() | nil,
          slack_markdown: String.t() | nil,
          default_subject: String.t() | nil,
          default_variable_values: map(),
          # Relations
          account_id: binary(),
          account: any(),
          # Timestamps
          inserted_at: any(),
          updated_at: any()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "message_templates" do
    field(:name, :string, null: false)
    field(:description, :string)
    field(:type, :string)
    field(:plain_text, :string)
    field(:markdown, :string)
    field(:raw_html, :string)
    field(:react_js, :string)
    field(:react_markdown, :string)
    field(:slack_markdown, :string)
    field(:default_subject, :string)
    field(:default_variable_values, :map)

    belongs_to(:account, Account)

    timestamps()
  end

  @doc false
  def changeset(message_template, attrs) do
    message_template
    |> cast(attrs, [
      :name,
      :description,
      :type,
      :account_id,
      :plain_text,
      :raw_html,
      :markdown,
      :react_js,
      :react_markdown,
      :slack_markdown,
      :default_subject,
      :default_variable_values
    ])
    |> validate_required([
      :account_id,
      :name
    ])
  end
end
