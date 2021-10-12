defmodule ChatApiWeb.EmailController do
  use ChatApiWeb, :controller

  alias ChatApi.MessageTemplates
  alias ChatApi.MessageTemplates.MessageTemplate

  @spec send(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send(
        conn,
        %{
          "credentials" => credentials,
          "from" => from,
          "to" => to,
          "subject" => subject
        } = payload
      ) do
    IO.inspect(payload, label: "Email payload")

    with {:ok, config} <- parse_config(credentials),
         {:ok, text_body, html_body} <- parse_email_body(payload) do
      # TODO: remove default/fallback values
      Swoosh.Email.new(
        from: from || "alex@papercups.io",
        to: to || "reichertjalex@gmail.com",
        subject: subject || "Hello world",
        text_body: text_body,
        html_body: html_body
      )
      # TODO: handle in worker?
      |> Swoosh.Mailer.deliver(config)
      |> IO.inspect(label: "Swoosh delivery result")
    else
      {:error, :invalid_config} -> IO.inspect(credentials, label: "Invalid credentials!")
      {:error, error} -> IO.inspect({error, payload}, label: "Invalid email params!")
      error -> IO.inspect(error, label: "Unexpected error!")
    end

    send_resp(conn, 200, "")
  end

  def send(conn, payload) do
    IO.inspect(payload, label: "Invalid email payload")

    send_resp(conn, 200, "")
  end

  defp parse_email_body(%{"body" => text_body}), do: {:ok, text_body, nil}

  defp parse_email_body(%{"text" => text_body, "html" => html_body}),
    do: {:ok, text_body, html_body}

  defp parse_email_body(%{"text_body" => text_body, "html_body" => html_body}),
    do: {:ok, text_body, html_body}

  defp parse_email_body(%{"message_template_id" => message_template_id, "data" => data})
       when is_map(data) do
    with %MessageTemplate{
           raw_html: raw_html,
           plain_text: plain_text
         } <- MessageTemplates.get_message_template!(message_template_id),
         # TODO: validate that "data" includes all necessary fields?
         {:ok, text_body} <- MessageTemplates.render(plain_text, data),
         {:ok, html_body} <- MessageTemplates.render(raw_html, data) do
      {:ok, text_body, html_body}
    end
  end

  defp parse_email_body(_params), do: {:error, :invalid_params}

  defp parse_config(%{"adapter" => "mailgun", "api_key" => api_key, "domain" => domain}),
    do:
      {:ok,
       [
         otp_app: :chat_api,
         adapter: Swoosh.Adapters.Mailgun,
         api_key: api_key,
         domain: domain
       ]}

  defp parse_config(%{"adapter" => "sendgrid", "api_key" => api_key}),
    do:
      {:ok,
       [
         otp_app: :chat_api,
         adapter: Swoosh.Adapters.Sendgrid,
         api_key: api_key
       ]}

  defp parse_config(%{"adapter" => "postmark", "api_key" => api_key}),
    do:
      {:ok,
       [
         otp_app: :chat_api,
         adapter: Swoosh.Adapters.Postmark,
         api_key: api_key
       ]}

  defp parse_config(%{
         "adapter" => "ses",
         "region" => region,
         "aws_access_key" => aws_access_key,
         "aws_secret_key" => aws_secret_key
       }),
       do:
         {:ok,
          [
            otp_app: :chat_api,
            adapter: Swoosh.Adapters.AmazonSES,
            region: region,
            access_key: aws_access_key,
            secret: aws_secret_key
          ]}

  # TODO: support Gmail API as well?
  defp parse_config(%{"adapter" => "gmail"}) do
    {:error, :invalid_config}
  end

  defp parse_config(_config), do: {:error, :invalid_config}
end
