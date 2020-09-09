defmodule ChatApi.Workers.SendConversationReplyEmail do
  use Oban.Worker,
    queue: :mailers,
    unique: [
      fields: [:args, :worker],
      # Unique by conversation id
      keys: [:conversation_id],
      # Only worry about uniqueness for unexecuted jobs
      states: [:available, :scheduled, :executing],
      # 3 min
      period: 180
    ]

  require Logger

  alias ChatApi.{Accounts, Conversations, Messages, Users}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message}}) do
    if has_valid_email_domain?() && reply_emails_enabled?() do
      Logger.info("Checking if we need to send reply email: #{inspect(message)}")

      send_email(message)
    else
      Logger.info("Skipping reply email (disabled): #{inspect(message)}")
    end

    :ok
  end

  def send_email(%{"user_id" => nil, "user" => nil}), do: nil

  def send_email(
        %{
          "seen_at" => nil,
          "user_id" => user_id,
          "account_id" => account_id,
          "customer_id" => nil,
          "conversation_id" => conversation_id
        } = _message
      ) do
    if Conversations.has_unseen_messages?(conversation_id) do
      Logger.info("Sending reply email!")

      email =
        ChatApi.Emails.send_conversation_reply_email(
          user: Users.get_user_info(user_id),
          customer: Conversations.get_conversation_customer!(conversation_id),
          account: Accounts.get_account!(account_id),
          messages:
            conversation_id
            |> Messages.list_by_conversation(account_id, limit: 5)
            |> Enum.reverse()
        )

      case email do
        {:ok, result} ->
          Logger.info("Sent reply email! #{inspect(result)}")

        {:error, reason} ->
          Logger.error("Failed to send email! #{inspect(reason)}")

        error ->
          Logger.error("Unexpected failure when sending reply email: #{inspect(error)}")
      end
    else
      Logger.info("Skipping reply email: no unseen messages")
    end
  end

  def send_email(_params), do: nil

  def has_valid_email_domain?() do
    System.get_env("DOMAIN") == "mail.papercups.io"
  end

  def reply_emails_enabled?() do
    case System.get_env("CONVERSATION_REPLY_EMAILS_ENABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
