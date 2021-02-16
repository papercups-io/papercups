defmodule ChatApi.Google.Gmail do
  def send_message(
        refresh_token,
        %{to: _to, from: _from, subject: _subject, text: _text} = params
      ) do
    with %{token: %{access_token: access_token}} <-
           ChatApi.Google.Auth.get_token!(refresh_token: refresh_token) do
      ChatApi.Emails.send_via_gmail(access_token, params)
    end
  end

  def list_messages(refresh_token, query \\ []) do
    q = query |> Enum.map_join(" ", fn {k, v} -> "#{k}:#{v}" end) |> URI.encode()
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=#{q}"
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

  def list_threads(refresh_token, query \\ []) do
    q = query |> Enum.map_join(" ", fn {k, v} -> "#{k}:#{v}" end) |> URI.encode()
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/threads?q=#{q}"
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

  def get_profile(refresh_token) do
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/profile"
    client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)
    %{body: result} = OAuth2.Client.get!(client, scope)

    result
  end

  def decode_message_body(text) do
    text |> String.replace("-", "+") |> String.replace("_", "/") |> Base.decode64()
  end

  # Example use case:
  #  token
  #   |> ChatApi.Google.Gmail.list_threads(in: "sent", subject: "October product updates")
  #   |> Map.get("threads", [])
  #   |> Enum.map(fn thread ->
  #     thread
  #     |> Map.get("id")
  #     |> ChatApi.Google.Gmail.get_thread(token)
  #     |> ChatApi.Google.Gmail.get_original_recipient()
  #   end)
  #
  # => outputs user emails that received the "October product updates" email
  def get_original_recipient(thread) do
    thread
    |> Map.get("messages")
    |> List.first()
    |> get_in(["payload", "headers"])
    |> Enum.find(fn h -> h["name"] == "To" end)
    |> Map.get("value")
  end

  def get_thread_messages(thread) do
    thread
    |> Map.get("messages")
    |> Enum.map(fn msg ->
      snippet = Map.get(msg, "snippet")

      msg
      |> get_in(["payload", "parts"])
      |> Enum.reduce(%{snippet: snippet}, fn part, acc ->
        [key, value] =
          case part do
            %{"mimeType" => "text/plain", "body" => %{"data" => encoded}} ->
              [:text, encoded]

            %{"mimeType" => "text/html", "body" => %{"data" => encoded}} ->
              [:html, encoded]

            _ ->
              [:invalid, nil]
          end

        case decode_message_body(value) do
          {:ok, decoded} -> Map.merge(acc, %{key => decoded})
          :error -> acc
        end
      end)
    end)
  end
end
