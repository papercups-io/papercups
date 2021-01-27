defmodule ChatApi.Repo.Migrations.MakeMessageBodyOptional do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      modify(:body, :text, null: true)
    end
  end
end
