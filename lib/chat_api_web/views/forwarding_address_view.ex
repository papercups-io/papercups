defmodule ChatApiWeb.ForwardingAddressView do
  use ChatApiWeb, :view
  alias ChatApiWeb.ForwardingAddressView

  def render("index.json", %{forwarding_addresses: forwarding_addresses}) do
    %{data: render_many(forwarding_addresses, ForwardingAddressView, "forwarding_address.json")}
  end

  def render("show.json", %{forwarding_address: forwarding_address}) do
    %{data: render_one(forwarding_address, ForwardingAddressView, "forwarding_address.json")}
  end

  def render("forwarding_address.json", %{forwarding_address: forwarding_address}) do
    %{
      id: forwarding_address.id,
      object: "forwarding_address",
      forwarding_email_address: forwarding_address.forwarding_email_address,
      source_email_address: forwarding_address.source_email_address,
      state: forwarding_address.state,
      description: forwarding_address.description,
      account_id: forwarding_address.account_id,
      created_at: forwarding_address.inserted_at,
      updated_at: forwarding_address.updated_at
    }
  end
end
