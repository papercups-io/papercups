defmodule ChatApiWeb.GettingStartedStepsView do
  use ChatApiWeb, :view

  def render("index.json", %{}) do
    %{
      object: "getting_started_steps",
      installed_chat_widget: false,
      invited_teammates: false,
      configured_profile: false,
      has_integrations: false,
      configured_storytime: false,
      has_upgraded_subscription: false,
    }
  end
end
