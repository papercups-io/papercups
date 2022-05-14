defmodule ChatApi.Emails do
  import Ecto.Query, warn: false

  require Logger

  alias ChatApi.{
    Accounts,
    Conversations,
    Mailbox,
    Repo,
    Users
  }

  alias ChatApi.Customers.Customer
  alias ChatApi.Emails.Email
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User
  alias ChatApi.Accounts.Account

  @from_address System.get_env("FROM_ADDRESS") || "noreply@mail.heypapercups.io"

  @spec send_ad_hoc_email(keyword()) :: {:error, any()} | {:ok, Tesla.Env.t()}
  def send_ad_hoc_email(to: to, from: from, subject: subject, text: text, html: html) do
    Mailbox.send_email(%Mailbox.Email{
      to: to,
      from: from,
      subject: subject,
      text_body: text,
      html_body: html
    })
  end

  @spec send_new_message_alerts(Message.t()) :: [{:error, any()} | {:ok, Tesla.Env.t()}]
  def send_new_message_alerts(%Message{} = message) do
    message
    |> get_users_to_email()
    |> Enum.map(fn email -> send_new_message_alert(email, message) end)
  end

  # TODO: Add some recent messages for context, rather than just a single message
  # (See the `conversation_reply` method for an example of this)
  @spec send_new_message_alert(binary(), Message.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def send_new_message_alert(email, %Message{
        body: body,
        conversation_id: conversation_id,
        customer_id: customer_id
      }) do
    customer = format_customer_name(customer_id)
    dashboard_url = "#{app_domain()}/conversations/#{conversation_id}"

    Mailbox.send_email(%Mailbox.Email{
      to: email,
      from: "alex@papercups.io",
      subject: "#{customer} has sent you a message",
      template: :new_message_alert,
      data: %{
        sender: customer,
        content: body,
        dashboard_url: dashboard_url
      }
    })
  end

  @spec send_welcome_email(binary()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def send_welcome_email(address) do
    Mailbox.send_email(%Mailbox.Email{
      to: address,
      from: "alex@papercups.io",
      subject: "Welcome to Papercups!",
      template: :welcome
    })
  end

  @spec send_password_reset_email(User.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def send_password_reset_email(%User{email: email, password_reset_token: token}) do
    Mailbox.send_email(%Mailbox.Email{
      to: email,
      from: @from_address,
      subject: "Link to reset your Papercups password",
      template: :password_reset,
      data: %{
        password_reset_url: "#{app_domain()}/reset?token=#{token}"
      }
    })
  end

  @spec send_user_invitation_email(User.t(), Account.t(), binary(), binary()) ::
          {:error, any} | {:ok, Tesla.Env.t()}
  def send_user_invitation_email(user, account, to_address, invitation_token) do
    company = account.company_name
    from_name = format_sender_name(user, account)
    from_address = user.email
    inviter = if from_name == company, do: from_address, else: "#{from_name} (#{from_address})"

    invitation_url =
      "#{app_domain()}/register/#{invitation_token}?#{URI.encode_query(%{email: to_address})}"

    subject =
      if from_name == company,
        do: "You've been invited to join #{company} on Papercups!",
        else: "#{from_name} has invited you to join #{company} on Papercups!"

    Mailbox.send_email(%Mailbox.Email{
      to: to_address,
      from: from_address,
      subject: subject,
      template: :user_invitation,
      data: %{
        inviter: inviter,
        company: company,
        invitation_url: invitation_url
      }
    })
  end

  @spec send_conversation_reply_email(keyword()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def send_conversation_reply_email(
        user: user,
        customer: customer,
        account: account,
        messages: messages
      ) do
    Mailbox.send_email(%Mailbox.Email{
      to: customer.email,
      from: @from_address,
      subject: "New message from #{account.company_name}!",
      template: :conversation_reply,
      data: %{
        recipient: customer.name,
        sender: format_sender_name(user, account),
        company: account.company_name,
        messages:
          Enum.map(messages, fn message ->
            %{
              sender: format_message_sender(message, account),
              content: message.body
            }
          end)
      },
      # 20 minutes
      schedule_in: 20 * 60,
      idempotency_period: 20 * 60,
      # Ensures uniqueness for these fields within the `idempotency_period`
      idempotency_key:
        :crypto.hash(:sha256, [
          "conversation_reply",
          customer.email,
          user.email,
          account.id
        ])
        |> Base.encode16()
    })
  end

  @spec send_mention_notification_email(keyword()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def send_mention_notification_email(
        sender: sender,
        recipient: recipient,
        account: account,
        messages: messages
      ) do
    conversation_id = messages |> List.first() |> Map.get(:conversation_id)
    dashboard_url = "#{app_domain()}/conversations/#{conversation_id}"

    Mailbox.send_email(%Mailbox.Email{
      to: recipient.email,
      from: @from_address,
      reply_to: sender.email,
      subject: "You were mentioned in a message on Papercups!",
      template: :mention_notification,
      data: %{
        recipient: format_sender_name(recipient),
        sender: format_sender_name(sender, account),
        dashboard_url: dashboard_url,
        messages:
          Enum.map(messages, fn message ->
            %{
              sender: format_message_sender(message, account),
              content: message.body
            }
          end)
      }
    })
  end

  defp format_message_sender(%Message{} = message, %Account{} = account) do
    case message do
      %{user: %User{} = user, customer_id: nil} -> format_sender_name(user, account)
      _ -> "You"
    end
  end

  @spec format_customer_name(nil | binary() | Customer.t()) :: binary()
  def format_customer_name(nil), do: "Anonymous User"

  def format_customer_name(customer_id) when is_binary(customer_id) do
    customer_id |> ChatApi.Customers.get_customer!() |> format_customer_name()
  end

  def format_customer_name(%Customer{} = customer) do
    case customer do
      %Customer{email: email, name: name} when is_binary(email) and is_binary(name) ->
        "#{name} (#{email})"

      %Customer{email: email} when is_binary(email) ->
        email

      %Customer{name: name} when is_binary(name) ->
        name

      _ ->
        "Anonymous User"
    end
  end

  @spec format_sender_name(User.t() | binary(), Account.t() | binary()) :: binary()
  def format_sender_name(%User{} = user, %Account{} = account) do
    case user.profile do
      %{display_name: display_name} when not is_nil(display_name) -> display_name
      %{full_name: full_name} when not is_nil(full_name) -> full_name
      _ -> "#{account.company_name} Team"
    end
  end

  def format_sender_name(user_id, account_id)
      when is_integer(user_id) and is_binary(account_id) do
    account = Accounts.get_account!(account_id)

    user_id
    |> Users.get_user_info()
    |> format_sender_name(account)
  end

  @spec format_sender_name(User.t() | binary()) :: binary() | nil
  def format_sender_name(%User{} = user) do
    case user.profile do
      %{display_name: display_name} when not is_nil(display_name) -> display_name
      %{full_name: full_name} when not is_nil(full_name) -> full_name
      _ -> nil
    end
  end

  def format_sender_name(user_id) when is_integer(user_id) do
    user_id
    |> Users.get_user_info()
    |> format_sender_name()
  end

  @spec get_users_to_email(Message.t()) :: [User.t()]
  def get_users_to_email(%Message{account_id: account_id} = message) do
    User
    |> join(:left, [u], s in assoc(u, :settings), as: :settings)
    |> where([u], u.account_id == ^account_id)
    |> where([u], is_nil(u.disabled_at) and is_nil(u.archived_at))
    |> where_alerts_enabled(is_first_message: Conversations.is_first_message?(message))
    |> select([u], u.email)
    |> Repo.all()
  end

  def where_alerts_enabled(query, is_first_message: true) do
    query
    |> where(
      [_u, settings: s],
      s.email_alert_on_new_message == true or s.email_alert_on_new_conversation == true
    )
  end

  def where_alerts_enabled(query, _) do
    query |> where([_u, settings: s], s.email_alert_on_new_message == true)
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

  defp app_domain() do
    case Application.get_env(:chat_api, :environment) do
      :dev -> "http://localhost:3000"
      _ -> "https://" <> System.get_env("BACKEND_URL", "app.papercups.io")
    end
  end

  defp disable_validity_check?() do
    case System.get_env("DISABLE_EMAIL_VALIDITY_CHECK") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
