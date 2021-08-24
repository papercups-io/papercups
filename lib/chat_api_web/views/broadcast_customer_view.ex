defmodule ChatApiWeb.BroadcastCustomerView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{BroadcastCustomerView, CustomerView}

  def render("index.json", %{broadcast_customers: broadcast_customers}) do
    %{data: render_many(broadcast_customers, BroadcastCustomerView, "broadcast_customer.json")}
  end

  def render("show.json", %{broadcast_customer: broadcast_customer}) do
    %{data: render_one(broadcast_customer, BroadcastCustomerView, "broadcast_customer.json")}
  end

  def render("broadcast_customer.json", %{broadcast_customer: broadcast_customer}) do
    %{
      id: broadcast_customer.id,
      object: "broadcast_customer",
      created_at: broadcast_customer.inserted_at,
      updated_at: broadcast_customer.updated_at,
      state: broadcast_customer.state,
      sent_at: broadcast_customer.sent_at,
      account_id: broadcast_customer.account_id,
      broadcast_id: broadcast_customer.broadcast_id,
      customer_id: broadcast_customer.customer_id,
      customer: render_one(broadcast_customer.customer, CustomerView, "customer.json")
    }
  end
end
