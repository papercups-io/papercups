defmodule ChatApi.Emails do
  import Ecto.Query, warn: false

  alias ChatApi.Repo
  alias ChatApi.Emails.Email
  alias ChatApi.Users.{User, UserSettings}

  def send_email_alerts(message, account_id, conversation_id) do
    account_id
    |> get_users_to_email()
    |> Enum.map(fn email -> Email.send(email, message, conversation_id) end)
  end

  def get_users_to_email(account_id) do
    query =
      from(u in User,
        join: s in UserSettings,
        on: s.user_id == u.id,
        where: u.account_id == ^account_id and s.email_alert_on_new_message == true,
        select: u.email
      )

    Repo.all(query)
  end
end
