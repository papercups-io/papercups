defmodule ChatApi.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Conversations.Conversation
  alias ChatApi.Messages.Message
  alias ChatApi.Accounts.Account

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customers" do
    field(:first_seen, :date)
    field(:last_seen, :date)
    field(:email, :string)
    field(:name, :string)
    field(:phone, :string)
    field(:external_id, :string)
    field(:browser, :string)
    field(:browser_version, :string)
    field(:browser_language, :string)
    field(:os, :string)
    field(:ip, :string)

    has_many(:messages, Message)
    has_many(:conversations, Conversation)
    belongs_to(:account, Account)

    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :first_seen,
      :last_seen,
      :account_id,
      :email,
      :name,
      :phone,
      :external_id,
      :browser,
      :browser_version,
      :browser_language,
      :os,
      :ip
    ])
    |> validate_required([:first_seen, :last_seen, :account_id])
  end

  def metadata_changeset(customer, attrs) do
    customer
    |> cast(attrs, [
      :email,
      :name,
      :phone,
      :external_id,
      :browser,
      :browser_version,
      :browser_language,
      :os,
      :ip
    ])
  end
end
