defmodule ChatApi.Emails do
  import Ecto.Query, warn: false

  alias ChatApi.Repo
  alias ChatApi.Emails.Email
  alias ChatApi.Users.{User, UserSettings}

  def send_new_message_alerts(message, account_id, conversation_id) do
    account_id
    |> get_users_to_email()
    |> Enum.map(fn email ->
      email |> Email.new_message_alert(message, conversation_id) |> deliver()
    end)
  end

  def send_welcome_email(address) do
    address |> Email.welcome() |> deliver()
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

  def deliver(email) do
    # Using try catch here because if someone is self hosting and doesn't need the email service it would error out
    # TODO: Find a better solution besides try catch probably in config.exs setup an empty mailer that doesn't do anything
    try do
      ChatApi.Mailer.deliver(email)
    rescue
      e ->
        IO.puts(
          "Email config environment variable may not have been setup properly: #{e.message}"
        )
    end
  end
end
