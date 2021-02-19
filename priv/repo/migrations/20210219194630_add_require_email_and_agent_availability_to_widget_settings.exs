defmodule ChatApi.Repo.Migrations.AddRequireEmailAndAgentAvailabilityToWidgetSettings do
  use Ecto.Migration

  def change do
    alter table(:widget_settings) do
      add(:show_agent_availability, :boolean, default: false)
      add(:agent_available_text, :string)
      add(:agent_unavailable_text, :string)
      add(:require_email_upfront, :boolean, default: false)
    end
  end
end
