defmodule ChatApiWeb.CustomerView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{CustomerView, TagView, CSVHelpers}

  @customer_csv_ordered_fields ~w(id name email created_at updated_at)a ++
                                 ~w(first_seen last_seen phone external_id)a ++
                                 ~w(host pathname current_url browser)a ++
                                 ~w(os ip time_zone)a

  def render("index.json", %{customers: customers}) do
    %{data: render_many(customers, CustomerView, "customer.json")}
  end

  def render("index.csv", %{customers: customers}) do
    customers
    |> render_many(CustomerView, "customer.json")
    |> CSVHelpers.dump_csv_rfc4180(@customer_csv_ordered_fields)
  end

  def render("show.json", %{customer: customer}) do
    %{data: render_one(customer, CustomerView, "customer.json")}
  end

  def render("basic.json", %{customer: customer}) do
    %{
      id: customer.id,
      object: "customer",
      name: customer.name,
      email: customer.email,
      created_at: customer.inserted_at,
      updated_at: customer.updated_at,
      phone: customer.phone,
      external_id: customer.external_id,
      host: customer.host,
      pathname: customer.pathname,
      current_url: customer.current_url,
      browser: customer.browser,
      os: customer.os,
      metadata: customer.metadata
    }
  end

  def render("customer.json", %{customer: customer}) do
    %{
      id: customer.id,
      object: "customer",
      name: customer.name,
      email: customer.email,
      created_at: customer.inserted_at,
      updated_at: customer.updated_at,
      first_seen: customer.first_seen,
      last_seen: customer.last_seen,
      phone: customer.phone,
      external_id: customer.external_id,
      host: customer.host,
      pathname: customer.pathname,
      current_url: customer.current_url,
      browser: customer.browser,
      os: customer.os,
      ip: customer.ip,
      metadata: customer.metadata,
      time_zone: customer.time_zone,
      tags: render_tags(customer.tags)
    }
  end

  # TODO: figure out a better way to handle this
  defp render_tags([_ | _] = tags) do
    render_many(tags, TagView, "tag.json")
  end

  defp render_tags(_tags), do: []
end
