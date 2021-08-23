defmodule ChatApiWeb.MessageTemplateView do
  use ChatApiWeb, :view
  alias ChatApiWeb.MessageTemplateView

  def render("index.json", %{message_templates: message_templates}) do
    %{data: render_many(message_templates, MessageTemplateView, "message_template.json")}
  end

  def render("show.json", %{message_template: message_template}) do
    %{data: render_one(message_template, MessageTemplateView, "message_template.json")}
  end

  def render("message_template.json", %{message_template: message_template}) do
    %{
      id: message_template.id,
      object: "message_template",
      name: message_template.name,
      description: message_template.description,
      type: message_template.type,
      account_id: message_template.account_id,
      plain_text: message_template.plain_text,
      raw_html: message_template.raw_html,
      markdown: message_template.markdown,
      react_js: message_template.react_js,
      react_markdown: message_template.react_markdown,
      slack_markdown: message_template.slack_markdown,
      default_variable_values: message_template.default_variable_values
    }
  end
end
