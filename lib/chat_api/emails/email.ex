defmodule ChatApi.Emails.Email do
  import Swoosh.Email
  import Ecto.Changeset

  @from_address System.get_env("FROM_ADDRESS") || ""
  @backend_url System.get_env("BACKEND_URL") || ""

  defstruct to_address: nil, message: nil

  # TODO: Move conversation id out the mailer should only care about the message
  def new_message_alert(to_address, message, conversation_id) do
    link =
      "<a href=\"https://#{@backend_url}/conversations/#{conversation_id}\">View in dashboard</a>"

    msg = "<b>#{message}</b>"
    html = "A new message has arrived:<br />" <> msg <> "<br /><br />" <> link
    text = "A new message has arrived: #{message}"

    new()
    |> to(to_address)
    |> from({"Papercups", @from_address})
    |> subject("A customer has sent you a message!")
    |> html_body(html)
    |> text_body(text)
  end

  def conversation_reply(
        to: to,
        from: from,
        reply_to: reply_to,
        company: company,
        messages: messages,
        customer: customer
      ) do
    new()
    |> to(to)
    |> from({from, @from_address})
    |> reply_to(reply_to)
    |> subject("New message from #{company}!")
    |> html_body(conversation_reply_html(messages, from: from, to: customer, company: company))
    |> text_body(conversation_reply_text(messages, from: from, to: customer, company: company))
  end

  # TODO: figure out a better way to create templates for these
  defp conversation_reply_text(messages, from: from, to: customer, company: company) do
    """
    Hi #{customer.name || "there"}!

    You've received a new message from your chat with #{company} (#{customer.current_url || ""}):

    #{
      Enum.map(messages, fn msg ->
        format_sender(msg, company) <> ": " <> msg.body <> "\n"
      end)
    }

    Best,
    #{from}
    """
  end

  defp format_agent(user, company) do
    case user do
      %{email: email, profile: nil} ->
        company || email

      %{email: email, profile: profile} ->
        profile.display_name || profile.full_name || company || email

      _ ->
        company || "Agent"
    end
  end

  defp format_sender(message, company) do
    case message do
      %{user: user, customer_id: nil} -> format_agent(user, company)
      %{customer_id: _customer_id} -> "You"
    end
  end

  defp conversation_reply_html(messages, from: from, to: customer, company: company) do
    """
    <p>Hi #{customer.name || "there"}!</p>
    <p>You've received a new message from your chat with
    <a href="#{customer.current_url}">#{company}</a>:</p>
    <hr />
    #{
      Enum.map(messages, fn msg ->
        "<p><strong>#{format_sender(msg, company)}</strong><br />#{msg.body}</p>"
      end)
    }
    <hr />
    <p>
    Best,<br />
    #{from}
    </p>
    """
  end

  # TODO: use env variables instead, come up with a better message
  def welcome(to_address) do
    new()
    |> to(to_address)
    |> from({"Alex", @from_address})
    |> reply_to("alex@papercups.io")
    |> subject("Welcome to Papercups!")
    |> html_body(welcome_email_html())
    |> text_body(welcome_email_text())
  end

  # TODO: figure out a better way to create templates for these
  defp welcome_email_text() do
    # TODO: include user's name if available
    """
    Hi there!

    Thanks for signing up for Papercups :)

    I'm Alex, one of the founders of Papercups along with Kam. If you have any questions,
    feedback, or need any help getting started, don't hesitate to reach out!

    Feel free to reply directly to this email, or contact me at alex@papercups.io

    Best,
    Alex

    We also have a Slack channel if you'd like to see what we're up to :)
    https://github.com/papercups-io/papercups#get-in-touch
    """
  end

  # TODO: figure out a better way to create templates for these
  defp welcome_email_html() do
    # TODO: include user's name if available
    """
    <p>Hi there!</p>

    <p>Thanks for signing up for Papercups :)</p>

    <p>I'm Alex, one of the founders of Papercups along with Kam. If you have any questions,
    feedback, or need any help getting started, don't hesitate to reach out!</p>

    <p>Feel free to reply directly to this email, or contact me at alex@papercups.io</p>

    <p>
    Best,<br />
    Alex
    </p>

    <p>
    PS: We also have a Slack channel if you'd like to see what we're up to :) <br/>
    https://github.com/papercups-io/papercups#get-in-touch
    </p>
    """
  end

  def password_reset(%ChatApi.Users.User{email: email, password_reset_token: token} = _user) do
    new()
    |> to(email)
    |> from({"Papercups", @from_address})
    |> subject("[Papercups] Link to reset your password")
    |> html_body(password_reset_html(token))
    |> text_body(password_reset_text(token))
  end

  defp get_app_domain() do
    if Mix.env() == :dev do
      "http://localhost:3000"
    else
      "https://" <> System.get_env("BACKEND_URL", "app.papercups.io")
    end
  end

  # TODO: figure out a better way to create templates for these
  defp password_reset_text(token) do
    """
    Hi there!

    Click the link below to reset your Papercups password:

    #{get_app_domain()}/reset?token=#{token}

    Best,
    Alex & Kam @ Papercups
    """
  end

  # TODO: figure out a better way to create templates for these
  defp password_reset_html(token) do
    link = "#{get_app_domain()}/reset?token=#{token}"

    """
    <p>Hi there!</p>

    <p>Click the link below to reset your Papercups password:</p>

    <a href="#{link}">#{link}</a>

    <p>
    Best,<br />
    Alex & Kam @ Papercups
    </p>
    """
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(email, attrs) do
    email
    |> cast(attrs, [:to_address, :message])
    |> validate_required([:to_address, :message])
  end
end
