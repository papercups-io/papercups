defmodule ChatApi.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Customers.Customer
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User
  alias ChatApi.WidgetSettings.WidgetSetting

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :company_name, :string
    has_many(:customers, Customer)
    has_many(:conversations, Conversation)
    has_many(:messages, Message)
    has_many(:users, User)
    has_one(:widget_setting, WidgetSetting)

    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:company_name])
    |> validate_required([:company_name])
  end
end
