defmodule ChatApi.Workers.SendConversationReplyEmail do
  @moduledoc false

  use Oban.Worker, queue: :mailers

  import Ecto.Query, warn: false

  require Logger

  alias ChatApi.{Accounts, Conversations, Messages, Repo, Users}

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"message" => message}}) do
    if has_valid_email_domain?() && reply_emails_enabled?() do
      Logger.info("Checking if we need to send reply email: #{inspect(message)}")

      send_email(message)
    else
      Logger.info("Skipping reply email (disabled): #{inspect(message)}")
    end

    :ok
  end

  @spec send_email(map()) :: :ok | :skipped | :error
  def send_email(%{"user_id" => nil, "user" => nil}), do: :skipped

  def send_email(
        %{
          "seen_at" => nil,
          "user_id" => user_id,
          "account_id" => account_id,
          "customer_id" => nil,
          "conversation_id" => conversation_id
        } = _message
      ) do
    if should_send_email?(conversation_id) do
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

        {:warning, reason} ->
          Logger.warn(reason)

        error ->
          Logger.error("Unexpected failure when sending reply email: #{inspect(error)}")
      end
    else
      Logger.info("Skipping reply email: no unseen messages")

      :skipped
    end
  end

  def send_email(_params), do: :error

  @spec get_pending_job_ids(binary()) :: [integer()]
  def get_pending_job_ids(conversation_id) do
    # TODO: double check this logic
    Oban.Job
    |> where(worker: "ChatApi.Workers.SendConversationReplyEmail")
    |> where([j], j.state != "discarded")
    |> Repo.all()
    |> Enum.filter(fn job -> job.args["message"]["conversation_id"] == conversation_id end)
    |> Enum.map(fn job -> job.id end)
  end

  def cancel_pending_jobs(%{conversation_id: conversation_id}) do
    conversation_id
    |> get_pending_job_ids()
    |> Enum.map(fn id -> Oban.cancel_job(id) end)
  end

  @doc """
  Check if we should send a notification email. Note that we only want to send
  these if the source is "chat" (we don't want to send when source is "slack")
  """
  @spec should_send_email?(binary()) :: boolean()
  def should_send_email?(conversation_id) do
    case Conversations.get_conversation!(conversation_id) do
      %{source: "chat"} -> Conversations.has_unseen_messages?(conversation_id)
      _ -> false
    end
  end

  @spec has_valid_email_domain? :: boolean()
  def has_valid_email_domain?() do
    System.get_env("DOMAIN") == "mail.heypapercups.io"
  end

  @spec reply_emails_enabled? :: boolean()
  def reply_emails_enabled?() do
    case System.get_env("CONVERSATION_REPLY_EMAILS_ENABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
