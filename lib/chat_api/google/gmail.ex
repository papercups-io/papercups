defmodule ChatApi.Google.Gmail do
  def send_message(refresh_token, to: to, from: from, subject: subject, message: message) do
    with %{token: %{access_token: access_token}} <-
           ChatApi.Google.Auth.get_token!(refresh_token: refresh_token) do
      ChatApi.Emails.send_via_gmail(
        to: to,
        from: from,
        subject: subject,
        message: message,
        access_token: access_token
      )
    end
  end

  def list_messages(refresh_token) do
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/messages"
    client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)
    %{body: result} = OAuth2.Client.get!(client, scope)

    result
  end

  def get_message(message_id, refresh_token) do
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{message_id}"
    client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)
    %{body: result} = OAuth2.Client.get!(client, scope)

    result
  end

  def list_threads(refresh_token) do
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/threads"
    client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)
    %{body: result} = OAuth2.Client.get!(client, scope)

    result
  end

  def get_thread(thread_id, refresh_token) do
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/threads/#{thread_id}?format=full"
    client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)
    %{body: result} = OAuth2.Client.get!(client, scope)

    result
  end
end
