defmodule ChatApi.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:full_name, :string)
      add(:display_name, :string)
      add(:profile_photo_url, :string)

      add(:user_id, references(:users, type: :integer), null: false)

      timestamps()
    end

    create(unique_index(:user_profiles, [:user_id]))
  end
end
