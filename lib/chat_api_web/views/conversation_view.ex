defmodule ChatApiWeb.ConversationView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{ConversationView, MessageView, CustomerView}

  def render("index.json", %{conversations: conversations}) do
    %{data: render_many(conversations, ConversationView, "expanded.json")}
  end

  def render("create.json", %{conversation: conversation}) do
    %{data: render_one(conversation, ConversationView, "basic.json")}
  end

  def render("update.json", %{conversation: conversation}) do
    %{data: render_one(conversation, ConversationView, "basic.json")}
  end

  def render("show.json", %{conversation: conversation}) do
    %{data: render_one(conversation, ConversationView, "expanded.json")}
  end

  def render("basic.json", %{conversation: conversation}) do
    %{
      id: conversation.id,
      created_at: conversation.inserted_at,
      status: conversation.status,
      read: conversation.read,
      priority: conversation.priority,
      account_id: conversation.account_id,
      customer_id: conversation.customer_id
    }
  end

  def render("expanded.json", %{conversation: conversation}) do
    %{
      id: conversation.id,
      created_at: conversation.inserted_at,
      status: conversation.status,
      read: conversation.read,
      priority: conversation.priority,
      account_id: conversation.account_id,
      customer_id: conversation.customer_id,
      assignee_id: conversation.assignee_id,
      customer: render_one(conversation.customer, CustomerView, "customer.json"),
      messages: render_many(conversation.messages, MessageView, "message.json")
    }
  end
end
