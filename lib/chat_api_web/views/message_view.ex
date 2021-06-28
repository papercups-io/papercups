defmodule ChatApiWeb.MessageView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{CustomerView, FileView, MessageView, UserView}

  def render("index.json", %{messages: messages}) do
    %{data: render_many(messages, MessageView, "message.json")}
  end

  def render("show.json", %{message: message}) do
    %{data: render_one(message, MessageView, "expanded.json")}
  end

  def render("message.json", %{message: message}) do
    %{
      id: message.id,
      object: "message",
      body: message.body,
      type: message.type,
      private: message.private,
      source: message.source,
      created_at: message.inserted_at,
      sent_at: message.sent_at,
      seen_at: message.seen_at,
      customer_id: message.customer_id,
      conversation_id: message.conversation_id,
      account_id: message.account_id,
      user_id: message.user_id,
      metadata: message.metadata
    }
  end

  def render("expanded.json", %{message: %{customer: %ChatApi.Customers.Customer{}} = message}) do
    %{
      id: message.id,
      object: "message",
      body: message.body,
      type: message.type,
      private: message.private,
      source: message.source,
      created_at: message.inserted_at,
      sent_at: message.sent_at,
      seen_at: message.seen_at,
      conversation_id: message.conversation_id,
      account_id: message.account_id,
      user_id: message.user_id,
      user: render_one(message.user, UserView, "user.json"),
      customer_id: message.customer_id,
      customer: render_one(message.customer, CustomerView, "basic.json"),
      attachments: render_attachments(message.attachments),
      metadata: message.metadata
    }
  end

  def render("expanded.json", %{message: message}) do
    %{
      id: message.id,
      object: "message",
      body: message.body,
      type: message.type,
      private: message.private,
      source: message.source,
      created_at: message.inserted_at,
      sent_at: message.sent_at,
      seen_at: message.seen_at,
      conversation_id: message.conversation_id,
      account_id: message.account_id,
      customer_id: message.customer_id,
      user_id: message.user_id,
      user: render_one(message.user, UserView, "user.json"),
      attachments: render_attachments(message.attachments),
      metadata: message.metadata
    }
  end

  # TODO: figure out the best way to handle this idiomatically
  defp render_attachments([_ | _] = attachments),
    do: render_many(attachments, FileView, "file.json")

  defp render_attachments(_attachments), do: []
end
