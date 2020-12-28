defmodule ChatApi.Companies.Company do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.{Accounts.Account, Customers.Customer}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "companies" do
    field(:name, :string)
    field(:description, :string)
    field(:external_id, :string)
    field(:website_url, :string)
    field(:industry, :string)
    field(:logo_image_url, :string)
    field(:slack_channel_id, :string)
    field(:slack_channel_name, :string)
    field(:metadata, :map)

    belongs_to(:account, Account)
    has_many(:customers, Customer)

    timestamps()
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [
      :name,
      :description,
      :account_id,
      :external_id,
      :website_url,
      :logo_image_url,
      :industry,
      :slack_channel_id,
      :slack_channel_name,
      :metadata
    ])
    |> validate_required([
      :name,
      :account_id
    ])
  end
end
