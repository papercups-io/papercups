defmodule ChatApi.Repo.Migrations.AddProfilePhotoUrlToCustomer do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add(:profile_photo_url, :string)
    end
  end
end
