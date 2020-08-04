defmodule ChatApi.Users.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_profiles" do
    field :display_name, :string
    field :full_name, :string
    field :profile_photo_url, :string
    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [:user_id, :full_name, :display_name, :profile_photo_url])
    |> validate_required([:user_id])
  end
end
