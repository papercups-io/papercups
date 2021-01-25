defmodule ChatApi.Users.UserSettings do
  use Ecto.Schema
  import Ecto.Changeset

  alias ChatApi.Users.User

  @type t :: %__MODULE__{
          email_alert_on_new_message: boolean(),
          # Foreign keys
          user_id: integer(),
          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_settings" do
    field :email_alert_on_new_message, :boolean, default: false

    belongs_to(:user, User, type: :integer)

    timestamps()
  end

  @doc false
  def changeset(user_settings, attrs) do
    user_settings
    |> cast(attrs, [:user_id, :email_alert_on_new_message])
    |> validate_required([:user_id])
  end
end
