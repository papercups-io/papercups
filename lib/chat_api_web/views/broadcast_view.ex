defmodule ChatApiWeb.BroadcastView do
  use ChatApiWeb, :view
  alias ChatApi.Broadcasts.Broadcast
  alias ChatApi.MessageTemplates.MessageTemplate
  alias ChatApiWeb.{BroadcastView, BroadcastCustomerView, MessageTemplateView}

  def render("index.json", %{broadcasts: broadcasts}) do
    %{data: render_many(broadcasts, BroadcastView, "broadcast.json")}
  end

  def render("show.json", %{broadcast: broadcast}) do
    %{data: render_one(broadcast, BroadcastView, "broadcast.json")}
  end

  def render("broadcast.json", %{broadcast: broadcast}) do
    %{
      id: broadcast.id,
      object: "broadcast",
      created_at: broadcast.inserted_at,
      updated_at: broadcast.updated_at,
      name: broadcast.name,
      description: broadcast.description,
      state: broadcast.state,
      subject: broadcast.subject,
      started_at: broadcast.started_at,
      finished_at: broadcast.finished_at,
      account_id: broadcast.account_id,
      message_template_id: broadcast.message_template_id
    }
    |> maybe_render_message_template(broadcast)
    |> maybe_render_broadcast_customers(broadcast)
  end

  defp maybe_render_broadcast_customers(json, %Broadcast{broadcast_customers: broadcast_customers})
       when is_list(broadcast_customers),
       do:
         Map.merge(json, %{
           broadcast_customers:
             render_many(broadcast_customers, BroadcastCustomerView, "broadcast_customer.json")
         })

  defp maybe_render_broadcast_customers(json, _), do: json

  defp maybe_render_message_template(json, %Broadcast{
         message_template: %MessageTemplate{} = message_template
       }),
       do:
         Map.merge(json, %{
           message_template:
             render_one(message_template, MessageTemplateView, "message_template.json")
         })

  defp maybe_render_message_template(json, _), do: json
end
