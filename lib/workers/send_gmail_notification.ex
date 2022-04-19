defmodule ChatApi.Workers.SendGmailNotification do
  @moduledoc false

  use Oban.Worker, queue: :mailers
  import Ecto.Query, warn: false
  require Logger
  alias ChatApi.{Conversations, Google, Messages}
  alias ChatApi.Conversations.Conversation
  alias ChatApi.Google.{GoogleAuthorization, GmailConversationThread}

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{
        args: %{
          "message" =>
            %{
              "id" => message_id,
              "account_id" => account_id,
              "conversation_id" => conversation_id,
              "user_id" => user_id,
              "body" => body
            } = message
        }
      }) do
    # TODO: clean this up a bit, move some logic into smaller functions
    with %Conversation{inbox_id: inbox_id} <- Conversations.get_conversation(conversation_id),
         %GoogleAuthorization{refresh_token: refresh_token} = authorization <-
           Google.get_authorization_by_account(account_id, %{
             inbox_id: inbox_id,
             client: "gmail",
             type: "support"
           }),
         %GmailConversationThread{
           gmail_initial_subject: gmail_initial_subject,
           gmail_thread_id: gmail_thread_id
         } <-
           Google.get_thread_by_conversation_id(conversation_id),
         %{
           "gmail_message_id" => gmail_message_id,
           "gmail_from" => gmail_from,
           "gmail_to" => gmail_to,
           "gmail_cc" => gmail_cc,
           "gmail_references" => gmail_references
         } = last_gmail_message <- extract_last_gmail_message!(conversation_id),
         {:ok, %{body: %{"emailAddress" => from}}} <- Google.Gmail.get_profile(refresh_token) do
      Logger.info("Last Gmail message: #{inspect(last_gmail_message)}")

      # TODO: double check logic for determining from/to/cc/etc
      # TODO: write tests for this logic!
      sender = Google.format_sender_display_name(authorization, user_id, account_id)
      last_from = Google.Gmail.extract_email_address(gmail_from)
      last_to = gmail_to |> String.split(",") |> Enum.map(&Google.Gmail.extract_email_address/1)

      to =
        if from == last_from do
          last_to
        else
          [last_from | last_to] |> Enum.uniq() |> Enum.reject(&(&1 == from))
        end

      cc =
        case gmail_cc do
          cc when is_binary(cc) ->
            cc |> String.split(",") |> Enum.map(&Google.Gmail.extract_email_address/1)

          _ ->
            []
        end

      references =
        case gmail_references do
          ref when is_binary(ref) -> ref <> " " <> gmail_message_id
          _ -> gmail_message_id
        end

      payload = %{
        from: {sender, from},
        subject: "Re: #{gmail_initial_subject}",
        text: body,
        to: to,
        cc: cc,
        in_reply_to: gmail_message_id,
        references: references,
        thread_id: gmail_thread_id,
        attachments: message |> Map.get("attachments", []) |> format_gmail_attachments()
      }

      Logger.info("Sending payload to Gmail: #{inspect(payload)}")

      case Google.Gmail.send_message(refresh_token, payload) do
        {:ok, %{body: %{"id" => gmail_message_id, "threadId" => ^gmail_thread_id}}} ->
          Logger.info("Gmail message sent: #{inspect(gmail_message_id)}")

          message_id
          |> Messages.get_message!()
          |> Messages.update_message(%{
            metadata: format_message_metadata(refresh_token, gmail_message_id)
          })

        {:error, error} ->
          Logger.error("Failed to send Gmail message: #{inspect(error)}")

        error ->
          Logger.error("Unexpected response from Gmail.send_message: #{inspect(error)}")
      end
    else
      error -> Logger.info("Skipped sending Gmail notification: #{inspect(error)}")
    end

    :ok
  end

  @spec format_message_metadata(binary(), binary()) :: map()
  def format_message_metadata(refresh_token, gmail_message_id) do
    case Google.Gmail.get_message(refresh_token, gmail_message_id) do
      {:ok, %{body: result}} ->
        result
        |> Google.Gmail.format_thread_message()
        |> Google.Gmail.format_message_metadata()

      _ ->
        %{}
    end
  end

  @spec extract_last_gmail_message!(binary()) :: map()
  def extract_last_gmail_message!(conversation_id) do
    conversation_id
    |> Conversations.get_conversation!()
    |> Map.get(:messages, [])
    |> Enum.map(& &1.metadata)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1["gmail_ts"])
    |> List.last()
  end

  @spec format_gmail_attachment(map()) :: Swoosh.Attachment.t() | nil
  def format_gmail_attachment(%{
        "file_url" => file_url,
        "filename" => filename,
        "content_type" => content_type
      }) do
    case ChatApi.Aws.download_file_url(file_url) do
      {:ok, %{body: data, status_code: 200}} ->
        Swoosh.Attachment.new({:data, data},
          content_type: content_type,
          filename: filename,
          type: :inline
        )

      _ ->
        nil
    end
  end

  def format_gmail_attachment(_), do: nil

  @spec format_gmail_attachment([map()]) :: [Swoosh.Attachment.t()]
  def format_gmail_attachments(attachments \\ []) do
    attachments
    |> Enum.map(&format_gmail_attachment/1)
    |> Enum.reject(&is_nil/1)
  end
end
