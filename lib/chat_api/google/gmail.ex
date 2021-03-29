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

  def list_history(refresh_token, query \\ []) do
    qs = URI.encode_query(query)
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/history?#{qs}"
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

  def decode_message_body(nil), do: :error

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
    |> Enum.map(fn %{
                     "id" => id,
                     "threadId" => thread_id,
                     "historyId" => history_id,
                     "labelIds" => label_ids,
                     "internalDate" => ts,
                     "sizeEstimate" => estimated_size,
                     "snippet" => snippet,
                     "payload" => payload
                   } = _msg ->
      headers =
        payload
        |> Map.get("headers", [])
        |> Enum.filter(fn %{"name" => name, "value" => _} ->
          Enum.member?(
            [
              "references",
              "in-reply-to",
              "from",
              "date",
              "message-id",
              "subject",
              "to",
              "content-type"
            ],
            String.downcase(name)
          )
        end)
        |> Enum.map(fn %{"name" => name, "value" => value} ->
          {String.downcase(name), value}
        end)
        |> Map.new()

      message = %{
        id: id,
        thread_id: thread_id,
        history_id: history_id,
        label_ids: label_ids,
        ts: ts,
        estimated_size: estimated_size,
        snippet: snippet,
        headers: headers,
        message_id: headers["message-id"],
        subject: headers["subject"],
        from: headers["from"],
        to: headers["to"],
        in_reply_to: headers["in-reply-to"],
        references: headers["references"],
        text: "",
        html:
          case get_in(payload, ["body", "data"]) do
            data when is_binary(data) -> decode_message_body(data)
            _ -> ""
          end
      }

      payload
      |> Map.get("parts", [])
      |> format_message_parts(message)
    end)
  end

  def format_message_parts(parts \\ [], message \\ %{}) do
    Enum.reduce(parts, message, fn part, acc ->
      case part do
        %{"parts" => embedded_parts} ->
          format_message_parts(embedded_parts, acc)

        %{"mimeType" => "text/plain", "body" => %{"data" => encoded}} ->
          case decode_message_body(encoded) do
            {:ok, decoded} -> Map.merge(acc, %{text: decoded})
            :error -> acc
          end

        %{"mimeType" => "text/html", "body" => %{"data" => encoded}} ->
          case decode_message_body(encoded) do
            {:ok, decoded} -> Map.merge(acc, %{html: decoded})
            :error -> acc
          end

        _ ->
          acc
      end
    end)
  end

  def extract_email_address(str) do
    case Regex.scan(~r/<(.*?)>/, str) do
      [[_match, email]] -> email
      _ -> str
    end
  end

  # Simple parsing logic

  # TODO: evaluate this repo as a more robust alternative:
  # https://github.com/hellogustav/elixir_email_reply_parser/blob/master/lib/elixir_email_reply_parser/parser.ex

  def remove_original_email(email) do
    email
    |> remove_quoted_email()
    |> remove_trailing_newlines()
    |> remove_trailing_dot()
    |> String.trim()
  end

  defp remove_quoted_email(body) do
    Enum.reduce(reply_header_formats(), body, fn regex, email_body ->
      regex |> Regex.split(email_body) |> List.first()
    end)
  end

  defp reply_header_formats do
    [
      ~r/\n\>?[[:space:]]*On.*<?\n?.*>?.*\n?wrote:\n?/
    ]
  end

  defp remove_trailing_newlines(body) do
    Regex.replace(~r/\n+$/, body, "")
  end

  defp remove_trailing_dot(body) do
    String.replace(body, ~r/[\x{1427}]/u, "")
  end
end
