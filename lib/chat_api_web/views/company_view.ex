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
      external_id: company.external_id,
      website_url: company.website_url,
      description: company.description,
      logo_image_url: company.logo_image_url,
      industry: company.industry,
      slack_channel_id: company.slack_channel_id,
      metadata: company.metadata
    }
  end
end
