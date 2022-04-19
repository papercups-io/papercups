defmodule ChatApi.Workers.SendMentionNotification do
  @moduledoc false

  use Oban.Worker, queue: :mailers

  import Ecto.Query, warn: false

  require Logger

  alias ChatApi.{Accounts, Users}
  alias ChatApi.Messages
  alias ChatApi.Messages.Message
  alias ChatApi.Users.User

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"message" => message, "user" => user}}) do
    if enabled?() && should_send_email?(user) do
      Logger.info("Checking if we need to send reply email: #{inspect(message)}")

      send_email(message, user)
    else
      Logger.info(
        "Skipping @mention notification email: #{inspect(message)} (user: #{inspect(user)})"
      )
    end

    :ok
  end

  @spec send_email(map()) :: :ok | :skipped | :error
  def send_email(%{"user_id" => nil, "user" => nil}, _), do: :skipped

  def send_email(
        %{
          "seen_at" => nil,
          "user_id" => sender_id,
          "account_id" => account_id,
          "customer_id" => nil,
          "conversation_id" => conversation_id
        } = _message,
        %{"id" => recipient_id, "email" => _email} = _user
      ) do
    Logger.info("Sending @mention notification email!")

    email =
      ChatApi.Emails.send_mention_notification_email(
        sender: Users.get_user_info(sender_id),
        recipient: Users.get_user_info(recipient_id),
        account: Accounts.get_account!(account_id),
        messages: get_recent_messages(conversation_id, account_id)
      )

    case email do
      {:ok, result} ->
        Logger.info("Sent @mention notification email! #{inspect(result)}")

      {:error, reason} ->
        Logger.error("Failed to send @mention notification email! #{inspect(reason)}")

      {:warning, reason} ->
        Logger.warn(reason)
    end
  end

  def send_email(_params), do: :error

  @spec get_recent_messages(binary(), binary()) :: [Message.t()]
  def get_recent_messages(conversation_id, account_id) do
    conversation_id
    |> Messages.list_by_conversation(%{"account_id" => account_id}, limit: 5)
    |> Enum.reverse()
  end

  @doc """
  Check that the user has a valid email before sending
  """
  @spec should_send_email?(User.t()) :: boolean()
  def should_send_email?(%{
        "email" => email,
        "disabled_at" => nil,
        "archived_at" => nil
      }),
      do: ChatApi.Emails.Helpers.valid_format?(email)

  def should_send_email?(_), do: false

  @spec enabled?() :: boolean()
  def enabled?() do
    has_valid_email_domain?() && mention_notification_emails_enabled?()
  end

  @spec has_valid_email_domain? :: boolean()
  def has_valid_email_domain?() do
    System.get_env("DOMAIN") == "mail.heypapercups.io"
  end

  @spec mention_notification_emails_enabled? :: boolean()
  def mention_notification_emails_enabled?() do
    # Should be enabled by default, unless the MENTION_NOTIFICATION_EMAILS_DISABLED is set
    case System.get_env("MENTION_NOTIFICATION_EMAILS_DISABLED") do
      x when x == "1" or x == "true" -> false
      _ -> true
    end
  end
end
