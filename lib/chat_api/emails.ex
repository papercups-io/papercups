defmodule ChatApi.Emails do
  import Ecto.Query, warn: false

  require Logger

  alias ChatApi.Repo
  alias ChatApi.Emails.Email
  alias ChatApi.Messages.Message
  alias ChatApi.Users.{User, UserSettings}
  alias ChatApi.Accounts.Account

  @type deliver_result() :: {:ok, term()} | {:error, binary()} | {:warning, binary()}

  @spec send_new_message_alerts(Message.t()) :: [deliver_result()]
  def send_new_message_alerts(message) do
    message
    |> Map.get(:account_id)
    |> get_users_to_email()
    |> Enum.map(fn email ->
      email |> Email.new_message_alert(message) |> deliver()
    end)
  end

  @spec send_welcome_email(binary()) :: deliver_result()
  def send_welcome_email(address) do
    address |> Email.welcome() |> deliver()
  end

  @spec send_password_reset_email(User.t()) :: deliver_result()
  def send_password_reset_email(user) do
    user |> Email.password_reset() |> deliver()
  end

  @spec format_sender_name(User.t(), Account.t()) :: binary
  def format_sender_name(user, account) do
    case user.profile do
      %{display_name: display_name} when not is_nil(display_name) -> display_name
      %{full_name: full_name} when not is_nil(full_name) -> full_name
      _ -> account.company_name
    end
  end

  @spec send_conversation_reply_email(keyword()) :: deliver_result()
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

  @spec send_via_gmail(keyword()) :: deliver_result()
  def send_via_gmail(
        to: to,
        from: from,
        subject: subject,
        message: message,
        access_token: access_token
      ) do
    Email.generic(
      to: to,
      from: from,
      subject: subject,
      message: message
    )
    |> deliver(access_token: access_token)
  end

  @spec get_users_to_email(binary()) :: [User.t()]
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

  @spec has_valid_to_addresses?(Email.t()) :: boolean()
  def has_valid_to_addresses?(email) do
    if disable_validity_check?() do
      true
    else
      Enum.all?(email.to, fn {_name, address} ->
        ChatApi.Emails.Helpers.valid?(address)
      end)
    end
  end

  @spec deliver(Email.t()) :: deliver_result()
  def deliver(email) do
    # Using try catch here because if someone is self hosting and doesn't need the email service it would error out
    # TODO: Find a better solution besides try catch probably in config.exs setup an empty mailer that doesn't do anything
    try do
      if has_valid_to_addresses?(email) do
        ChatApi.Mailers.Mailgun.deliver(email)
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

  # TODO: figure out how to clean this up
  @spec deliver(Email.t(), keyword()) :: deliver_result()
  def deliver(email, access_token: access_token) do
    try do
      if has_valid_to_addresses?(email) do
        ChatApi.Mailers.Gmail.deliver(email, access_token: access_token)
      else
        {:warning, "Skipped sending to potentially invalid email: #{inspect(email.to)}"}
      end
    rescue
      e ->
        IO.puts("Error sending via Gmail: #{e.message}")

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
