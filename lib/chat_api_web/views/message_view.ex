defmodule ChatApiWeb.MessageView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{CustomerView, MessageView, UserView}

  def render("index.json", %{messages: messages}) do
    %{data: render_many(messages, MessageView, "message.json")}
  end

  def render("show.json", %{message: message}) do
    %{data: render_one(message, MessageView, "expanded.json")}
  end

  def render("message.json", %{message: message}) do
    %{
      id: message.id,
      body: message.body,
      created_at: message.inserted_at,
      sent_at: message.sent_at,
      seen_at: message.seen_at,
      customer_id: message.customer_id,
      conversation_id: message.conversation_id,
      account_id: message.account_id,
      user_id: message.user_id
    }
  end

  def render("expanded.json", %{message: %{customer: %ChatApi.Customers.Customer{}} = message}) do
    %{
      id: message.id,
      body: message.body,
      created_at: message.inserted_at,
      sent_at: message.sent_at,
      seen_at: message.seen_at,
      conversation_id: message.conversation_id,
      account_id: message.account_id,
      user_id: message.user_id,
      user: render_one(message.user, UserView, "user.json"),
      customer_id: message.customer_id,
      customer: render_one(message.customer, CustomerView, "basic.json")
    }
  end

  def render("expanded.json", %{message: message}) do
    %{
      id: message.id,
      body: message.body,
      created_at: message.inserted_at,
      sent_at: message.sent_at,
      seen_at: message.seen_at,
      conversation_id: message.conversation_id,
      account_id: message.account_id,
      customer_id: message.customer_id,
      user_id: message.user_id,
      user: render_one(message.user, UserView, "user.json")
    }
  end
end
