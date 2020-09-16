defmodule ChatApiWeb.CustomerView do
  use ChatApiWeb, :view
  alias ChatApiWeb.CustomerView

  def render("index.json", %{customers: customers}) do
    %{data: render_many(customers, CustomerView, "customer.json")}
  end

  def render("show.json", %{customer: customer}) do
    %{data: render_one(customer, CustomerView, "customer.json")}
  end

  def render("basic.json", %{customer: customer}) do
    %{
      id: customer.id,
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
      os: customer.os
    }
  end

  def render("customer.json", %{customer: customer}) do
    %{
      id: customer.id,
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
      ip: customer.ip
    }
  end
end
