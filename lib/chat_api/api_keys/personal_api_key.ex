defmodule ChatApi.ApiKeys.PersonalApiKey do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Accounts.Account
  alias ChatApi.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "personal_api_keys" do
    field(:label, :string)
    field(:value, :string)
    field(:last_used_at, :utc_datetime)

    belongs_to(:account, Account)
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(personal_api_key, attrs) do
    personal_api_key
    |> cast(attrs, [:label, :value, :last_used_at, :account_id, :user_id])
    |> validate_required([:label, :value, :account_id, :user_id])
    |> unique_constraint(:value)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
  end
end
