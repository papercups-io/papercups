defmodule ChatApi.Twilio.Notification do
  @moduledoc """
  A module to handle sending Twilio notifications.
  """

  require Logger

  alias ChatApi.{
    Conversations,
    Conversations.Conversation,
    Customers.Customer,
    Twilio,
    Messages.Message
  }

  @spec notify_sms(ChatApi.Messages.Message.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def notify_sms(%Message{
        conversation_id: conversation_id,
        body: body,
        account_id: account_id,
        customer: %Customer{phone: customer_phone}
      }) do
    with conversation <- Conversations.get_conversation!(conversation_id),
         {:ok, _} <- validate_source(conversation),
         twilio_authorization <- Twilio.get_authorization_by_account(account_id),
         {:ok, _} <- Twilio.Client.validate_phone(customer_phone, twilio_authorization) do
      %{
        To: customer_phone,
        From: twilio_authorization.from_phone_number,
        Body: body
      }
      |> Twilio.Client.send_message(twilio_authorization)
    else
      error ->
        Logger.error("Skipped sending Twilio message: #{inspect(error)}")
        error
    end
  end

  defp validate_source(%Conversation{source: "sms"} = conversation), do: {:ok, conversation}
  defp validate_source(_), do: {:error, :not_sms_conversation}
end
