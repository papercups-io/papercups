defmodule ChatApi.Emails do
  import Ecto.Query, warn: false

  require Logger

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

  def send_password_reset_email(user) do
    user |> Email.password_reset() |> deliver()
  end

  def format_sender_name(user, account) do
    case user.profile do
      nil -> account.company_name
      profile -> profile.display_name || profile.full_name
    end
  end

  def send_conversation_reply_email(
        user: user,
        customer: customer,
        account: account,
        messages: messages
      ) do
    Email.conversation_reply(
      to: customer.email,
      from: format_sender_name(user, account),
      reply_to: user.email,
      company: account.company_name,
      messages: messages,
      customer: customer
    )
    |> deliver()
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

  def has_valid_to_addresses?(email) do
    if disable_validity_check?() do
      true
    else
      Enum.all?(email.to, fn {_name, address} ->
        ChatApi.Emails.Helpers.valid?(address)
      end)
    end
  end

  def deliver(email) do
    # Using try catch here because if someone is self hosting and doesn't need the email service it would error out
    # TODO: Find a better solution besides try catch probably in config.exs setup an empty mailer that doesn't do anything
    try do
      if has_valid_to_addresses?(email) do
        ChatApi.Mailer.deliver(email)
      else
        {:warning, "Skipped sending to potentially invalid email: #{inspect(email.to)}"}
      end
    rescue
      e ->
        IO.puts(
          "Email config environment variable may not have been setup properly: #{e.message}"
        )

        {:error, e.message}
    end
  end

  defp disable_validity_check?() do
    case System.get_env("DISABLE_EMAIL_VALIDITY_CHECK") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
