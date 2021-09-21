defmodule ChatApiWeb.WidgetSettingsView do
  use ChatApiWeb, :view
  alias ChatApiWeb.{AccountView, WidgetSettingsView}

  def render("show.json", %{widget_settings: widget_settings}) do
    %{data: render_one(widget_settings, WidgetSettingsView, "expanded.json")}
  end

  def render("update.json", %{widget_settings: widget_settings}) do
    %{data: render_one(widget_settings, WidgetSettingsView, "basic.json")}
  end

  def render("basic.json", %{widget_settings: widget_settings}) do
    %{
      id: widget_settings.id,
      object: "widget_settings",
      created_at: widget_settings.inserted_at,
      updated_at: widget_settings.updated_at,
      title: widget_settings.title,
      subtitle: widget_settings.subtitle,
      color: widget_settings.color,
      greeting: widget_settings.greeting,
      new_message_placeholder: widget_settings.new_message_placeholder,
      show_agent_availability: widget_settings.show_agent_availability,
      agent_available_text: widget_settings.agent_available_text,
      agent_unavailable_text: widget_settings.agent_unavailable_text,
      require_email_upfront: widget_settings.require_email_upfront,
      is_open_by_default: widget_settings.is_open_by_default,
      custom_icon_url: widget_settings.custom_icon_url,
      iframe_url_override: widget_settings.iframe_url_override,
      icon_variant: widget_settings.icon_variant,
      email_input_placeholder: widget_settings.email_input_placeholder,
      new_messages_notification_text: widget_settings.new_messages_notification_text,
      is_branding_hidden: widget_settings.is_branding_hidden,
      base_url: widget_settings.base_url,
      away_message: widget_settings.away_message,
      inbox_id: widget_settings.inbox_id
    }
  end

  def render("expanded.json", %{widget_settings: widget_settings}) do
    %{
      id: widget_settings.id,
      object: "widget_settings",
      created_at: widget_settings.inserted_at,
      updated_at: widget_settings.updated_at,
      title: widget_settings.title,
      subtitle: widget_settings.subtitle,
      color: widget_settings.color,
      greeting: widget_settings.greeting,
      new_message_placeholder: widget_settings.new_message_placeholder,
      show_agent_availability: widget_settings.show_agent_availability,
      agent_available_text: widget_settings.agent_available_text,
      agent_unavailable_text: widget_settings.agent_unavailable_text,
      require_email_upfront: widget_settings.require_email_upfront,
      is_open_by_default: widget_settings.is_open_by_default,
      custom_icon_url: widget_settings.custom_icon_url,
      iframe_url_override: widget_settings.iframe_url_override,
      icon_variant: widget_settings.icon_variant,
      email_input_placeholder: widget_settings.email_input_placeholder,
      new_messages_notification_text: widget_settings.new_messages_notification_text,
      is_branding_hidden: widget_settings.is_branding_hidden,
      base_url: widget_settings.base_url,
      away_message: widget_settings.away_message,
      inbox_id: widget_settings.inbox_id,
      account: render_one(widget_settings.account, AccountView, "basic.json")
    }
  end
end
