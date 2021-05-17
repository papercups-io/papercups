defmodule ChatApi.Workers.SendEmailConversationReceiptEmail do
  @moduledoc false

  use Oban.Worker, queue: :mailers

  alias ChatApi.{Accounts, Customers, Messages}

  require Logger

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{
        args: %{
          "account_id" => account_id,
          "customer_id" => customer_id,
          "message_id" => message_id
        }
      }) do
    if send_email_conversation_receipt_email_enabled?() do
      account = Accounts.get_account!(account_id)
      customer = Customers.get_customer!(customer_id)
      message = Messages.get_message!(message_id)

      Logger.info("Sending email conversation receipt email to #{customer.email}")

      deliver_result =
        ChatApi.Emails.send_email_conversation_receipt_email(
          customer: customer,
          account: account,
          message: message
        )

      case deliver_result do
        {:ok, result} ->
          Logger.info("Successfully sent email conversation receipt email: #{inspect(result)}")

        {:warning, reason} ->
          Logger.warn("Warning when sending email conversation receipt email: #{inspect(reason)}")

        {:error, reason} ->
          Logger.error("Error when sending email conversation receipt email: #{inspect(reason)}")
      end
    else
      Logger.info("Skipping email conversation receipt email to #{customer_id}")
    end

    :ok
  end

  def send_email_conversation_receipt_email_enabled?() do
    true
    # case System.get_env("EMAIL_CONVERSATION_RECEIPT_EMAIL_ENABLED") do
    #   x when x == "1" or x == "true" -> true
    #   _ -> false
    # end
  end
end
