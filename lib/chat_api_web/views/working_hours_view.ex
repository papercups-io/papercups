defmodule ChatApiWeb.WorkingHoursView do
  use ChatApiWeb, :view

  def render("working_hours.json", %{working_hours: working_hours}) do
    %{
      day: working_hours.day,
      start_minute: working_hours.start_minute,
      end_minute: working_hours.end_minute
    }
  end
end
