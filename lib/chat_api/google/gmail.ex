defmodule ChatApi.Google.Gmail do
  require Logger

  def send_message(
        refresh_token,
        %{to: _to, from: _from, subject: _subject, text: _text} = params
      ) do
    with %{token: %{access_token: access_token}} <-
           ChatApi.Google.Auth.get_token!(refresh_token: refresh_token) do
      scope = "https://www.googleapis.com/gmail/v1/users/me/messages/send"
      client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)

      body =
        params
        |> ChatApi.Emails.Email.gmail()
        |> ChatApi.Mailers.GmailAdapter.parse(
          access_token: access_token,
          thread_id: params[:thread_id]
        )

      %{body: result} = OAuth2.Client.post!(client, scope, body)

      result
    end
  end

  def reply_to_thread(
        refresh_token,
        %{
          to: _to,
          from: _from,
          subject: _subject,
          text: _text,
          in_reply_to: _in_reply_to,
          references: _references,
          thread_id: _gmail_thread_id
        } = params
      ) do
    send_message(refresh_token, params)
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

  def get_message_attachment(message_id, attachment_id, refresh_token) do
    scope =
      "https://gmail.googleapis.com/gmail/v1/users/me/messages/#{message_id}/attachments/#{
        attachment_id
      }"

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

    case OAuth2.Client.get(client, scope) do
      {:ok, %{body: result}} ->
        result

      {:error, %{body: %{"error" => %{"code" => 404}}}} ->
        Logger.warn("Gmail thread #{inspect(thread_id)} not found")

        nil

      {:error, error} ->
        raise error
    end
  end

  def list_history(refresh_token, query \\ []) do
    qs = URI.encode_query(query)
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/history?#{qs}"
    client = ChatApi.Google.Auth.get_token!(refresh_token: refresh_token)

    case OAuth2.Client.get(client, scope) do
      {:ok, %{body: result}} ->
        result

      {:error, %{body: %{"error" => %{"code" => 404}}}} ->
        Logger.warn("Gmail history not found for #{inspect(qs)}")

        nil

      {:error, error} ->
        raise error
    end
  end

  def list_labels(refresh_token, query \\ []) do
    qs = URI.encode_query(query)
    scope = "https://gmail.googleapis.com/gmail/v1/users/me/labels?#{qs}"
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

  #############################################################################
  # Helpers
  #############################################################################

  def decode_message_body(nil), do: :error

  def decode_message_body(text) do
    text
    |> String.replace("-", "+")
    |> String.replace("_", "/")
    |> Base.decode64()
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

  defmodule GmailAttachment do
    defstruct [:message_id, :attachment_id, :filename, :mime_type, :data]

    @type t :: %__MODULE__{
            message_id: String.t(),
            attachment_id: String.t(),
            filename: String.t(),
            mime_type: String.t(),
            data: binary() | nil
          }
  end

  def download_message_attachment(
        %GmailAttachment{
          attachment_id: attachment_id,
          message_id: message_id,
          filename: filename
        },
        refresh_token
      ) do
    identifier = ChatApi.Aws.generate_unique_filename(filename)

    with %{"data" => encoded_attachment_data} <-
           get_message_attachment(message_id, attachment_id, refresh_token),
         {:ok, decoded_attachment_data} <- decode_message_body(encoded_attachment_data),
         {:ok, _result} <- ChatApi.Aws.upload_binary(decoded_attachment_data, identifier) do
      ChatApi.Aws.get_file_url(identifier)
    end
  end

  defmodule GmailMessage do
    defstruct [
      :id,
      :thread_id,
      :history_id,
      :label_ids,
      :ts,
      :estimated_size,
      :snippet,
      :headers,
      :message_id,
      :subject,
      :from,
      :to,
      :cc,
      :bcc,
      :in_reply_to,
      :references,
      :text,
      :html,
      :formatted_text,
      attachments: []
    ]

    @type t :: %__MODULE__{
            id: String.t() | nil,
            thread_id: String.t() | nil,
            history_id: String.t() | nil,
            label_ids: [String.t()],
            ts: String.t() | nil,
            estimated_size: number() | nil,
            snippet: String.t() | nil,
            headers: String.t() | nil,
            message_id: String.t() | nil,
            subject: String.t() | nil,
            from: String.t() | nil,
            to: String.t() | nil,
            cc: String.t() | nil,
            bcc: String.t() | nil,
            in_reply_to: String.t() | nil,
            references: String.t() | nil,
            text: String.t() | nil,
            html: String.t() | nil,
            formatted_text: String.t() | nil,
            attachments: [GmailAttachment.t()]
          }
  end

  defmodule GmailThread do
    defstruct [:thread_id, :history_id, :messages]

    @type t :: %__MODULE__{
            thread_id: String.t(),
            history_id: String.t(),
            messages: [GmailMessage.t()]
          }
  end

  @spec format_thread(map(), keyword()) :: GmailThread.t()
  def format_thread(
        %{
          "historyId" => history_id,
          "id" => thread_id,
          "messages" => [_ | _] = messages
        },
        opts \\ []
      ) do
    %GmailThread{
      thread_id: thread_id,
      history_id: history_id,
      messages:
        messages
        |> Enum.map(&format_thread_message/1)
        |> Enum.reject(fn msg ->
          case opts[:exclude_labels] do
            excluded when is_list(excluded) ->
              Enum.any?(msg.label_ids, fn label -> Enum.member?(excluded, label) end)

            _ ->
              false
          end
        end)
    }
  end

  def get_thread_messages(thread) do
    thread
    |> Map.get("messages", [])
    |> Enum.map(&format_thread_message/1)
  end

  @spec format_thread_message(map()) :: GmailMessage.t()
  def format_thread_message(
        %{
          "id" => id,
          "threadId" => thread_id,
          "historyId" => history_id,
          "labelIds" => label_ids,
          "internalDate" => ts,
          "sizeEstimate" => estimated_size,
          "snippet" => snippet,
          "payload" => payload
        } = _msg
      ) do
    headers =
      payload
      |> Map.get("headers", [])
      |> format_message_headers()

    default_text =
      payload
      |> get_in(["body", "data"])
      |> decode_message_body()
      |> case do
        {:ok, decoded} -> decoded
        :error -> ""
      end

    message = %GmailMessage{
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
      cc: headers["cc"],
      bcc: headers["bcc"],
      in_reply_to: headers["in-reply-to"],
      references: headers["references"],
      text: default_text,
      html: default_text,
      formatted_text: remove_original_email(default_text),
      attachments: []
    }

    payload
    |> Map.get("parts", [])
    |> format_message_parts(message)
  end

  @spec format_message_headers(list()) :: map()
  def format_message_headers(headers \\ []) do
    headers
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
          "cc",
          "bcc",
          "content-type"
        ],
        String.downcase(name)
      )
    end)
    |> Enum.map(fn %{"name" => name, "value" => value} ->
      {String.downcase(name), value}
    end)
    |> Map.new()
  end

  @spec format_message_parts(list(), map()) :: map()
  def format_message_parts(parts, %GmailMessage{} = message) do
    Enum.reduce(parts, message, fn part, acc ->
      case part do
        %{"parts" => embedded_parts} ->
          format_message_parts(embedded_parts, acc)

        %{"mimeType" => "text/plain", "body" => %{"data" => encoded}} ->
          case decode_message_body(encoded) do
            {:ok, decoded} ->
              Map.merge(acc, %{
                text: decoded,
                formatted_text: remove_original_email(decoded)
              })

            :error ->
              acc
          end

        %{"mimeType" => "text/html", "body" => %{"data" => encoded}} ->
          case decode_message_body(encoded) do
            {:ok, decoded} -> Map.merge(acc, %{html: decoded})
            :error -> acc
          end

        %{
          "mimeType" => mime_type,
          "filename" => filename,
          "body" => %{"attachmentId" => attachment_id}
        } ->
          Map.merge(acc, %{
            attachments: [
              %GmailAttachment{
                filename: filename,
                attachment_id: attachment_id,
                message_id: message.id,
                mime_type: mime_type
              }
              | acc.attachments
            ]
          })

        _ ->
          acc
      end
    end)
  end

  defmodule GmailMessageMetadata do
    defstruct [
      :gmail_id,
      :gmail_thread_id,
      :gmail_history_id,
      :gmail_label_ids,
      :gmail_ts,
      :gmail_snippet,
      :gmail_message_id,
      :gmail_subject,
      :gmail_from,
      :gmail_to,
      :gmail_cc,
      :gmail_bcc,
      :gmail_in_reply_to,
      :gmail_references
    ]

    @type t :: %__MODULE__{
            gmail_id: String.t() | nil,
            gmail_thread_id: String.t() | nil,
            gmail_history_id: String.t() | nil,
            gmail_label_ids: [String.t()],
            gmail_ts: String.t() | nil,
            gmail_snippet: String.t() | nil,
            gmail_message_id: String.t() | nil,
            gmail_subject: String.t() | nil,
            gmail_from: String.t() | nil,
            gmail_to: String.t() | nil,
            gmail_cc: String.t() | nil,
            gmail_bcc: String.t() | nil,
            gmail_in_reply_to: String.t() | nil,
            gmail_references: String.t() | nil
          }
  end

  def format_message_metadata(message) do
    %GmailMessageMetadata{
      gmail_to: message.to,
      gmail_from: message.from,
      gmail_cc: Map.get(message, :cc),
      gmail_bcc: Map.get(message, :bcc),
      gmail_subject: message.subject,
      gmail_label_ids: message.label_ids,
      gmail_in_reply_to: message.in_reply_to,
      gmail_references: message.references,
      gmail_ts: message.ts,
      gmail_thread_id: message.thread_id,
      gmail_id: message.id,
      gmail_message_id: message.message_id,
      gmail_history_id: message.history_id
    }
    |> Map.from_struct()
  end

  def extract_email_address(nil), do: nil

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
