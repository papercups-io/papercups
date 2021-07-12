defmodule ChatApi.Emails.Email do
  import Swoosh.Email
  import Ecto.Changeset

  alias ChatApi.Customers.Customer
  alias ChatApi.Messages.Message
  alias ChatApi.Users.UserProfile

  @type t :: Swoosh.Email.t()

  @from_address System.get_env("FROM_ADDRESS") || ""
  @backend_url System.get_env("BACKEND_URL") || ""

  defstruct to_address: nil, message: nil

  def generic(to: to, from: from, subject: subject, text: text, html: html) do
    new()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> text_body(text)
    |> html_body(html)
  end

  def gmail(
        %{
          to: to,
          from: from,
          subject: subject,
          text: text,
          in_reply_to: in_reply_to,
          references: references
        } = params
      ) do
    new()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> cc(Map.get(params, :cc, []))
    |> bcc(Map.get(params, :bcc, []))
    |> header("In-Reply-To", in_reply_to)
    |> header("References", references)
    |> text_body(text)
    |> html_body(Map.get(params, :html))
  end

  def gmail(%{to: to, from: from, subject: subject, text: text} = params) do
    new()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> cc(Map.get(params, :cc, []))
    |> bcc(Map.get(params, :bcc, []))
    |> text_body(text)
    |> html_body(Map.get(params, :html))
  end

  # TODO: Add some recent messages for context, rather than just a single message
  # (See the `conversation_reply` method for an example of this)
  def new_message_alert(
        to_address,
        %Message{
          body: body,
          conversation_id: conversation_id,
          customer_id: customer_id
        } = _message
      ) do
    customer =
      case customer_id do
        id when is_binary(id) -> ChatApi.Customers.get_customer!(id)
        _ -> nil
      end

    {subject, intro} =
      case customer do
        %Customer{email: email, name: name} when is_binary(email) and is_binary(name) ->
          {"#{name} (#{email}) has sent you a message", "New message from #{name} (#{email}):"}

        %Customer{email: email} when is_binary(email) ->
          {"#{email} has sent you a message", "New message from #{email}:"}

        %Customer{name: name} when is_binary(name) ->
          {"#{name} has sent you a message", "New message from #{name}:"}

        _ ->
          {"A customer has sent you a message (conversation #{conversation_id})",
           "New message from an anonymous user:"}
      end

    link =
      "<a href=\"https://#{@backend_url}/conversations/#{conversation_id}\">View in dashboard</a>"

    html = intro <> "<br />" <> "<b>#{body}</b>" <> "<br /><br />" <> link
    text = intro <> " " <> body

    new()
    |> to(to_address)
    |> from({"Papercups", @from_address})
    |> subject(subject)
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

      %{email: email, profile: %UserProfile{} = profile} ->
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
    #{Enum.map(messages, fn msg -> format_message_html(msg, company) end)}
    <hr />
    <p>
    Best,<br />
    #{from}
    </p>
    """
  end

  defp format_message_html(message, company) do
    markdown = """
    **#{format_sender(message, company)}**\s\s
    #{message.body}
    """

    fallback = """
    <p>
      <strong>#{format_sender(message, company)}</strong><br />
      #{message.body}
    </p>
    """

    case Earmark.as_html(markdown) do
      {:ok, html, _} -> html
      _ -> fallback
    end
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

  def user_invitation(
        %{
          company: company,
          from_address: from_address,
          from_name: from_name,
          invitation_token: invitation_token,
          to_address: to_address
        } = _params
      ) do
    subject =
      if from_name == company,
        do: "You've been invited to join #{company} on Papercups!",
        else: "#{from_name} has invited you to join #{company} on Papercups!"

    intro_line =
      if from_name == company,
        do: "#{from_address} has invited you to join #{company} on Papercups!",
        else: "#{from_name} (#{from_address}) has invited you to join #{company} on Papercups!"

    invitation_url =
      "#{get_app_domain()}/register/#{invitation_token}?#{URI.encode_query(%{email: to_address})}"

    new()
    |> to(to_address)
    |> from({"Alex", @from_address})
    |> reply_to("alex@papercups.io")
    |> subject(subject)
    |> html_body(
      user_invitation_email_html(%{
        intro_line: intro_line,
        invitation_url: invitation_url
      })
    )
    |> text_body(
      user_invitation_email_text(%{
        intro_line: intro_line,
        invitation_url: invitation_url
      })
    )
  end

  defp user_invitation_email_text(
         %{
           invitation_url: invitation_url,
           intro_line: intro_line
         } = _params
       ) do
    """
    Hi there!

    #{intro_line}

    Click the link below to sign up:

    #{invitation_url}

    Best,
    Alex & Kam @ Papercups
    """
  end

  # TODO: figure out a better way to create templates for these
  defp user_invitation_email_html(
         %{
           invitation_url: invitation_url,
           intro_line: intro_line
         } = _params
       ) do
    """
    <p>Hi there!</p>

    <p>#{intro_line}</p>

    <p>Click the link below to sign up:</p>

    <a href="#{invitation_url}">#{invitation_url}</a>

    <p>
    Best,<br />
    Alex & Kam @ Papercups
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
    if Application.get_env(:chat_api, :environment) == :dev do
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

  @spec changeset(any(), map()) :: Ecto.Changeset.t()
  def changeset(email, attrs) do
    email
    |> cast(attrs, [:to_address, :message])
    |> validate_required([:to_address, :message])
  end
end
