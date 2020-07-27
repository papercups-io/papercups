defmodule ChatApi.Emails do
  alias ChatApi.Emails.Email

  def send_email_alerts(users, message, conversation_id) do
    users
    |> Enum.filter(fn u -> u.email_alert_on_new_message end)
    |> Enum.map(fn u -> Email.send(u.email, message, conversation_id) end)
  end
end
