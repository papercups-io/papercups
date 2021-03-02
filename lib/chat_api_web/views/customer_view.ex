defmodule ChatApiWeb.CustomerView do
  use ChatApiWeb, :view

  alias ChatApiWeb.{
    CompanyView,
    ConversationView,
    CustomerView,
    MessageView,
    NoteView,
    TagView,
    CSVHelpers
  }

  alias ChatApi.Companies.Company
  alias ChatApi.Customers.Customer

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
      profile_photo_url: customer.profile_photo_url,
      company_id: customer.company_id,
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
      profile_photo_url: customer.profile_photo_url,
      company_id: customer.company_id,
      host: customer.host,
      pathname: customer.pathname,
      current_url: customer.current_url,
      browser: customer.browser,
      os: customer.os,
      ip: customer.ip,
      metadata: customer.metadata,
      time_zone: customer.time_zone
    }
    |> maybe_render_tags(customer)
    |> maybe_render_notes(customer)
    |> maybe_render_conversations(customer)
    |> maybe_render_messages(customer)
    |> maybe_render_company(customer)
  end

  defp maybe_render_tags(json, %Customer{tags: tags}) when is_list(tags),
    do: Map.merge(json, %{tags: render_many(tags, TagView, "tag.json")})

  defp maybe_render_tags(json, _), do: json

  defp maybe_render_notes(json, %Customer{notes: notes}) when is_list(notes),
    do: Map.merge(json, %{notes: render_many(notes, NoteView, "note.json")})

  defp maybe_render_notes(json, _), do: json

  defp maybe_render_conversations(json, %Customer{conversations: conversations})
       when is_list(conversations) do
    Map.merge(json, %{conversations: render_many(conversations, ConversationView, "basic.json")})
  end

  defp maybe_render_conversations(json, _), do: json

  defp maybe_render_messages(json, %Customer{messages: messages}) when is_list(messages),
    do: Map.merge(json, %{messages: render_many(messages, MessageView, "message.json")})

  defp maybe_render_messages(json, _), do: json

  defp maybe_render_company(json, %Customer{company: company}) do
    case company do
      nil ->
        Map.merge(json, %{company: nil})

      %Company{} = company ->
        Map.merge(json, %{company: render_one(company, CompanyView, "company.json")})

      _ ->
        json
    end
  end

  defp maybe_render_company(json, _), do: json
end
