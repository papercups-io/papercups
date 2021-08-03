defmodule ChatApiWeb.CompanyView do
  use ChatApiWeb, :view
  alias ChatApiWeb.CompanyView

  def render("index.json", %{companies: companies}) do
    %{data: render_many(companies, CompanyView, "company.json")}
  end

  def render("show.json", %{company: company}) do
    %{data: render_one(company, CompanyView, "company.json")}
  end

  def render("company.json", %{company: company}) do
    %{
      id: company.id,
      object: "company",
      name: company.name,
      created_at: company.inserted_at,
      updated_at: company.updated_at,
      account_id: company.account_id,
      external_id: company.external_id,
      website_url: company.website_url,
      description: company.description,
      logo_image_url: company.logo_image_url,
      industry: company.industry,
      slack_channel_id: company.slack_channel_id,
      slack_channel_name: company.slack_channel_name,
      slack_team_id: company.slack_team_id,
      slack_team_name: company.slack_team_name,
      metadata: company.metadata
    }
  end
end
