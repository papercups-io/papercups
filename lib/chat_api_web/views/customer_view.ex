defmodule ChatApiWeb.CustomerView do
  use ChatApiWeb, :view

  alias ChatApiWeb.{
    CompanyView,
    ConversationView,
    CustomerView,
    IssueView,
    MessageView,
    NoteView,
    TagView,
    CSVHelpers
  }

  alias ChatApi.Companies.Company
  alias ChatApi.Customers.Customer

  @customer_csv_ordered_fields ~w(id name email created_at updated_at)a ++
                                 ~w(first_seen last_seen_at phone external_id)a ++
                                 ~w(host pathname current_url browser)a ++
                                 ~w(os ip time_zone)a

  def render("index.json", %{page: page}) do
    %{
      data: render_many(page.entries, CustomerView, "customer.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("index.csv", %{page: page}) do
    page.entries
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
      metadata: customer.metadata,
      title: customer.name || customer.email || "Anonymous User"
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
      last_seen_at: customer.last_seen_at,
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
      time_zone: customer.time_zone,
      title: customer.name || customer.email || "Anonymous User"
    }
    |> maybe_render_tags(customer)
    |> maybe_render_issues(customer)
    |> maybe_render_notes(customer)
    |> maybe_render_conversations(customer)
    |> maybe_render_messages(customer)
    |> maybe_render_company(customer)
  end

  defp maybe_render_tags(json, %Customer{tags: tags}) when is_list(tags),
    do: Map.merge(json, %{tags: render_many(tags, TagView, "tag.json")})

  defp maybe_render_tags(json, _), do: json

  defp maybe_render_issues(json, %Customer{issues: issues}) when is_list(issues),
    do: Map.merge(json, %{issues: render_many(issues, IssueView, "issue.json")})

  defp maybe_render_issues(json, _), do: json

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
