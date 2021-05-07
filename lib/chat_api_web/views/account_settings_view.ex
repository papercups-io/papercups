defmodule ChatApiWeb.AccountSettingsView do
  use ChatApiWeb, :view

  def render("account_settings.json", %{account_settings: account_settings}) do
    %{
      disable_automated_reply_emails: account_settings.disable_automated_reply_emails,
      conversation_reminders_enabled: account_settings.conversation_reminders_enabled,
      conversation_reminder_hours_interval: account_settings.conversation_reminder_hours_interval,
      max_num_conversation_reminders: account_settings.max_num_conversation_reminders
    }
  end
end
